# Agentic AI with Jac — Working Examples

Companion code for the blog post **[Agentic AI with Jac: A Programming Language That Knows What an Agent Is](https://blogs.jaseci.org/2026/05/12/building-agentic-ai-with-jac/)**.

The post describes **seven patterns** for building agents in [Jac](https://docs.jaseci.org/) — three for what happens inside a single agent iteration (the **Mind**) and four for how work moves between iterations (the **Flow**). This repo has each pattern as a self-contained `.jac` file that compiles with `jac check` and runs end-to-end with `jac run`.

| # | Pattern | File | What it shows |
|---|---------|------|---------------|
| **Mind 1** | Generate | [mind/1_generate.jac](mind/1_generate.jac) | An LLM call is a function — the signature is the prompt (MTP). |
| **Mind 2** | Extract | [mind/2_extract.jac](mind/2_extract.jac) | The return type is the schema; the runtime validates and retries. |
| **Mind 3** | Invoke | [mind/3_invoke.jac](mind/3_invoke.jac) | Tools are plain functions; the runtime runs the ReAct loop. |
| **Flow 1** | Pipe | [flow/1_pipe.jac](flow/1_pipe.jac) | Sequential steps as nodes; the walker carries the result forward. |
| **Flow 2** | Route | [flow/2_route.jac](flow/2_route.jac) | `visit [-->] by llm(...)` picks which specialist node to run. |
| **Flow 3** | Loop | [flow/3_loop.jac](flow/3_loop.jac) | A named `RetryEdge` + typed `Quality` verdict drive critique-and-revise. |
| **Flow 4** | Spawn | [flow/4_spawn.jac](flow/4_spawn.jac) | `flow ... spawn` / `wait` fan out parallel walkers, then synthesize. |

## Prerequisites

```bash
pip install jaclang byllm        # Jac 0.14.x + the byLLM plugin (tested on byllm 0.6.7)
```

Set an API key for whichever model you use (see [.env.example](.env.example)). The examples default to `openai/gpt-4o-mini`, which needs `OPENAI_API_KEY`.

## Run

```bash
jac run mind/1_generate.jac
jac run flow/4_spawn.jac
# ...etc
```

The Flow examples build a persistent graph on `root`. If you re-run one and see stale or duplicated state, reset it first:

```bash
jac clean        # clears the local graph state, then re-run
```

## How these differ from the blog snippets

The blog snippets are trimmed for reading. Three small, real things they leave out — included here so the code actually runs:

1. **A model has to be bound to `llm`.** The blog writes a bare `by llm()`. Each file here adds:
   ```jac
   import from byllm.llm { Model }
   glob llm = Model(model_name="openai/gpt-4o-mini");
   ```
   Swap `model_name` for any [litellm](https://docs.litellm.ai/docs/providers)-supported model (e.g. `anthropic/claude-sonnet-4-6`, `gemini/gemini-2.0-flash`).

2. **A walker spawned on `root` needs an initial hop.** `root spawn W` puts the walker *on* root; it won't reach the first pipeline node on its own. The Pipe and Loop walkers add:
   ```jac
   can begin with Root entry { visit [-->]; }
   ```

3. **A `by llm()` method needs semantic context.** A node or walker method like `def run(topic: str) -> str by llm();` needs either a `has` field or a `sem` to build its prompt — otherwise byLLM returns the rendered prompt template instead of calling the model. Pipe, Loop, and Spawn give each method a `sem`:
   ```jac
   sem Draft.run = "Write a first-draft technical explanation of the topic.";
   ```
   In Spawn, the `wait` results are also wrapped in `str(...)` before being passed to `synthesize` — `wait` yields an untyped (`any`) walker, and the type checker needs a concrete `str` for the parameters.

## License

MIT
