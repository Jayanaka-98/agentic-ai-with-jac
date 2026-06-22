"""Mind pattern 1 -- Generate: an LLM call is a function.

The intent is written once. The signature `def answer(question: str) -> str`
is what the LLM sees -- the function name, the parameter, and the return type
together tell the model what to do. byLLM builds the prompt from these code
semantics. This is Meaning-Typed Programming.
"""

import from byllm.llm { Model }

# The blog snippets write a bare `llm()`. A model has to be bound to that name;
# swap the model_name for any litellm-supported model you have a key for.
glob llm = Model(model_name="openai/gpt-4o-mini");

def answer(question: str) -> str by llm();

with entry {
    response = answer("What are three interesting facts about computer architecture?");
    print(response);
}
