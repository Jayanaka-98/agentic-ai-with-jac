"""Mind pattern 2 -- Extract: an LLM call returns typed data.

The return type `PaperClassification` IS the schema. The runtime introspects
it, sends it to the model, validates the response, and retries automatically
with the validation error in scope. No hand-rolled try / json.loads /
ValidationError block, no defensive None check on the caller.
"""

import from byllm.llm { Model }

glob llm = Model(model_name="openai/gpt-4o-mini");

enum Topic { HARDWARE, SOFTWARE, NETWORKS, AI, OTHER }

obj PaperClassification {
    has topic: Topic;
    has one_line_summary: str;
    has key_contributions: list[str];
}

def classify_paper(title: str, abstract: str) -> PaperClassification by llm();
sem classify_paper = "Classify a research paper by its title and abstract.";

with entry {
    result = classify_paper(
        title="Attention Is All You Need",
        abstract="The dominant sequence transduction models are based on complex "
                 "recurrent or convolutional neural networks. We propose the "
                 "Transformer, based solely on attention mechanisms."
    );
    # result.topic is a Topic enum member, result.key_contributions is list[str]
    print("Topic:", result.topic);
    print("Summary:", result.one_line_summary);
    print("Contributions:", result.key_contributions);
}
