"""Mind pattern 3 -- Invoke: the LLM calls tools in a ReAct loop.

Tools are ordinary functions. The runtime introspects their signatures,
exposes them to the model, runs the tool-use loop, and returns when the model
is done. No JSON schema, no dispatch dict, no hand-written ReAct loop.
"""

import from byllm.llm { Model }

glob llm = Model(model_name="openai/gpt-4o-mini");

# Tool stubs (in a real app these'd hit an API).
def search_papers(query: str) -> str { return f"3 papers found for '{query}'"; }
def get_citations(paper_id: str) -> int { return len(paper_id) * 100; }
def summarize_abstract(text: str) -> str { return f"Summary of: {text[:30]}..."; }

def research(query: str) -> str by llm(
    tools=[search_papers, get_citations, summarize_abstract]
);
sem research = "Research a topic by searching papers, checking citations, and summarizing findings.";

with entry {
    findings = research("Recent papers on transformer architectures and their citation impact");
    print(findings);
}
