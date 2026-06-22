"""Flow pattern 3 -- Loop: repeat until a typed quality check passes.

The loop is a named edge `RetryEdge` between the Evaluate and Revise nodes. A
reader scanning the graph immediately sees what kind of loop this is. The exit
condition rides on a typed `Quality` verdict returned by Evaluate, not on a
string match, and the maximum retry count is a typed field on the edge rather
than a magic number in a function body.
"""

import from byllm.llm { Model }

glob llm = Model(model_name="openai/gpt-4o-mini");

enum Quality { GOOD, NEEDS_IMPROVEMENT }

obj Review {
    has quality: Quality;
    has weaknesses: list[str];
    has suggestion: str;
}

edge RetryEdge {
    has reason: str = "Verdict was NEEDS_IMPROVEMENT";
    has max_retries: int = 3;
}

node Draft    { def run(topic: str) -> str by llm(); }
node Evaluate { def run(draft: str, topic: str) -> Review by llm(); }
node Revise   { def run(draft: str, feedback: str) -> str by llm(); }
node Approved {}

sem Draft.run    = "Write a first-draft tutorial section on the topic.";
sem Evaluate.run = "Critique the draft as a tutorial on the topic and return a typed verdict.";
sem Revise.run   = "Rewrite the draft to address the feedback.";

walker TutorialWriter {
    has topic: str;
    has draft: str = "";
    has feedback: str = "";
    has version: int = 1;

    can begin with Root entry {
        visit [-->];
    }

    can do_draft with Draft entry {
        self.draft = here.run(self.topic);
        visit [-->];
    }

    can do_evaluate with Evaluate entry {
        review = here.run(self.draft, self.topic);
        if review.quality == Quality.GOOD {
            visit [-->][?:Approved];
        } else {
            self.feedback = f"{review.weaknesses}. {review.suggestion}";
            visit [->:RetryEdge:->];
        }
    }

    can do_revise with Revise entry {
        self.version += 1;
        self.draft = here.run(self.draft, self.feedback);
        visit [-->];
    }
}

with entry {
    draft = Draft();   eval_n = Evaluate();
    revise = Revise(); done   = Approved();

    root ++> draft ++> eval_n;
    eval_n ++> done;
    eval_n +>:RetryEdge:+> revise;
    revise ++> eval_n;

    writer = root spawn TutorialWriter(topic="How cache coherence works in multicore processors");
    print(f"Final draft (version {writer.version}):\n{writer.draft}");
}
