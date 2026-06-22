"""Flow pattern 4 -- Spawn: fan out parallel work, fan in the results.

SurveyAgent spawns three independent walkers with `flow root spawn`, then
collects their results with `wait`. Each researcher carries its own scoped lens
and context, so three focused prompts run concurrently rather than one bloated
prompt holding every tool. Synthesis runs only after all three complete.

The LLM calls here are module-level `by llm()` functions called from inside the
walker abilities -- this is byLLM's documented OSP pattern and the most robust
way to combine `by llm()` with `flow`/`wait`.
"""

import from byllm.llm { Model }

glob llm = Model(model_name="openai/gpt-4o-mini");

def search_papers(query: str) -> str { return f"papers on '{query}'"; }
def get_citations(paper_id: str) -> int { return 1247; }

def investigate(topic: str, lens: str) -> str by llm(tools=[search_papers, get_citations]);
sem investigate = "Research the topic from the given lens, using the tools, and report findings.";

def synthesize(topic: str, hw: str, sw: str, ai: str) -> str by llm();
sem synthesize = "Combine the hardware, software, and AI research notes into one survey.";

walker HardwareResearcher {
    has topic: str;
    has result: str = "";
    can start with Root entry {
        self.result = investigate(self.topic, "hardware: chips, memory, accelerators");
    }
}
walker SoftwareResearcher {
    has topic: str;
    has result: str = "";
    can start with Root entry {
        self.result = investigate(self.topic, "software: compilers, runtimes, serving systems");
    }
}
walker AIResearcher {
    has topic: str;
    has result: str = "";
    can start with Root entry {
        self.result = investigate(self.topic, "AI: model architectures and algorithms");
    }
}

walker SurveyAgent {
    has topic: str;
    has response: str = "";

    can start with Root entry {
        hw_task = flow root spawn HardwareResearcher(topic=self.topic);
        sw_task = flow root spawn SoftwareResearcher(topic=self.topic);
        ai_task = flow root spawn AIResearcher(topic=self.topic);

        hw: any = wait hw_task;
        sw: any = wait sw_task;
        ai: any = wait ai_task;

        # `wait` yields an untyped (any) walker; str(...) gives the type checker
        # a concrete str to pass into synthesize's str parameters.
        self.response = synthesize(
            self.topic, str(hw.result), str(sw.result), str(ai.result)
        );
    }
}

with entry {
    survey = root spawn SurveyAgent(topic="Efficient inference for large language models");
    print(survey.response);
}
