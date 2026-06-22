"""Flow pattern 4 -- Spawn: fan out parallel work, fan in the results.

SurveyAgent spawns three independent walkers with `flow root spawn`, then
collects their results with `wait`. Each researcher carries its own scoped tool
list and its own context, so three focused prompts run concurrently rather than
one bloated prompt holding nine tools. The synthesis step `self.synthesize(...)`
only runs after all three workers have completed.

Two things this needs beyond the bare sketch:
  * a `sem` on each `by llm()` method, so byLLM has the semantic context to
    build the prompt (a method with neither a `sem` nor a `has` field returns
    its prompt template instead of calling the model).
  * `synthesize` takes the researcher walkers themselves (typed `any`) and byLLM
    reads their `topic`/`result` fields directly -- no string extraction. The
    `any` is needed because `wait` yields an `<Unknown>`-typed value, which the
    checker refuses to bind to an explicit walker type.
"""

import from byllm.llm { Model }

glob llm = Model(model_name="openai/gpt-4o-mini");

def search_papers(query: str) -> str { return f"papers on '{query}'"; }
def get_citations(paper_id: str) -> int { return 1247; }

walker HardwareResearcher {
    has topic: str;
    has result: str = "";
    def investigate(topic: str) -> str by llm(tools=[search_papers, get_citations]);
    can start with Root entry {
        self.result = self.investigate(self.topic);
    }
}
sem HardwareResearcher.investigate = "Research the topic from a hardware angle (chips, memory, accelerators) using the tools.";

walker SoftwareResearcher {
    has topic: str;
    has result: str = "";
    def investigate(topic: str) -> str by llm(tools=[search_papers, get_citations]);
    can start with Root entry {
        self.result = self.investigate(self.topic);
    }
}
sem SoftwareResearcher.investigate = "Research the topic from a software angle (compilers, runtimes, serving) using the tools.";

walker AIResearcher {
    has topic: str;
    has result: str = "";
    def investigate(topic: str) -> str by llm(tools=[search_papers, get_citations]);
    can start with Root entry {
        self.result = self.investigate(self.topic);
    }
}
sem AIResearcher.investigate = "Research the topic from an AI/ML angle (model architectures, algorithms) using the tools.";

walker SurveyAgent {
    has topic: str;
    has response: str = "";
    def synthesize(topic: str, hw: any, sw: any, ai: any) -> str by llm();

    can start with Root entry {
        hw_task = flow root spawn HardwareResearcher(topic=self.topic);
        sw_task = flow root spawn SoftwareResearcher(topic=self.topic);
        ai_task = flow root spawn AIResearcher(topic=self.topic);

        hw: any = wait hw_task;
        sw: any = wait sw_task;
        ai: any = wait ai_task;

        # Pass the researcher walkers themselves -- byLLM reads each one's
        # topic/result fields directly, no string extraction needed.
        self.response = self.synthesize(self.topic, hw, sw, ai);
    }
}
sem SurveyAgent.synthesize = "Combine the hardware, software, and AI research notes into one survey.";

with entry {
    survey = root spawn SurveyAgent(topic="Efficient inference for large language models");
    print(survey.response);
}
