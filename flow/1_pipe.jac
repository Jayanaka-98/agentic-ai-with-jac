"""Flow pattern 1 -- Pipe: sequential composition.

Each step is its own node (Draft, Examples, Summary), connected by edges. The
walker visits each in order, calling its `run` method and carrying the result
forward in `self.text`. Each step has its own scoped prompt that only sees the
data the walker carries. Inserting a new step means adding a node and an edge
instead of editing a prompt.

Note the walker's `can begin with Root entry { visit [-->]; }`: a walker
spawned on root sits there until told to move to the first node.
"""

import from byllm.llm { Model }

# The blog snippets write a bare `llm()`; a model must be bound to that name.
# Swap the model_name for any litellm-supported model you have a key for.
glob llm = Model(model_name="openai/gpt-4o-mini");

node Draft    { def run(topic: str) -> str by llm(); }
node Examples { def run(draft: str) -> str by llm(); }
node Summary  { def run(detail: str) -> str by llm(); }
node Done     {}

# A `by llm()` method needs semantic context to build its prompt; `sem` gives
# each step its own scoped instruction without polluting the model's output.
sem Draft.run    = "Write a first-draft technical explanation of the topic.";
sem Examples.run = "Revise the draft, weaving in concrete worked examples.";
sem Summary.run  = "Condense the text into a tight 3-4 sentence summary.";

walker Explainer {
    has topic: str;
    has text: str = "";

    can begin with Root entry {
        visit [-->];
    }
    can do_draft with Draft entry {
        self.text = here.run(self.topic);
        visit [-->];
    }
    can do_examples with Examples entry {
        self.text = here.run(self.text);
        visit [-->];
    }
    can do_summary with Summary entry {
        self.text = here.run(self.text);
        visit [-->];
    }
}

with entry {
    draft = Draft();  ex = Examples();  summ = Summary();  done = Done();
    root ++> draft;  draft ++> ex;  ex ++> summ;  summ ++> done;
    explainer = root spawn Explainer(topic="How cache coherence works in multicore processors");
    print(explainer.text);
}
