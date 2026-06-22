"""Flow pattern 2 -- Route: pick which handler runs based on what came in.

Each specialist is a node with a `description`. The line
`visit [-->] by llm(...)` lets the model read each connected node's description
and pick which one to visit. Adding a specialist means adding one node -- no
classifier prompt, no dispatch table.
"""

import from byllm.llm { Model }

glob llm = Model(model_name="openai/gpt-4o-mini");

node HardwareExpert {
    has description: str = "Expert in CPU, GPU, memory hierarchies, chip fabrication";
    def answer(q: str) -> str by llm();
    can respond with ResearchAssistant entry {
        visitor.response = self.answer(visitor.query);
    }
}
node SoftwareExpert {
    has description: str = "Expert in compilers, operating systems, runtimes";
    def answer(q: str) -> str by llm();
    can respond with ResearchAssistant entry {
        visitor.response = self.answer(visitor.query);
    }
}
node AIExpert {
    has description: str = "Expert in neural networks, LLMs, machine learning systems";
    def answer(q: str) -> str by llm();
    can respond with ResearchAssistant entry {
        visitor.response = self.answer(visitor.query);
    }
}

walker ResearchAssistant {
    has query: str;
    has response: str = "";
    can route with Root entry {
        visit [-->] by llm(incl_info={"User query": self.query});
    }
}

with entry {
    root ++> HardwareExpert();
    root ++> SoftwareExpert();
    root ++> AIExpert();

    q = "How do branch predictors work in modern CPUs?";
    r = root spawn ResearchAssistant(query=q);
    print(r.response);
}
