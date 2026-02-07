# AI Study Planner with Knowledge Graph

**Name:** Zhiyu Shuai  
**UMID:** 82429725  
**Course:** EECS 449 - Extra Credit Assignment 1

## What Is This?

An AI-powered study planner built with Jac. Instead of a basic todo list, I wanted to build something that actually uses Jac's graph structure in a meaningful way — so I made a learning tool where topics are connected through prerequisite edges, and the system uses the SM-2 spaced repetition algorithm to schedule reviews.

The main ideas:
- **Knowledge graph** — topics are nodes, prerequisites are edges, so the graph structure is central to how the app works
- **SM-2 spaced repetition** — the algorithm Anki uses to schedule flashcard reviews (calculates intervals based on how well you recalled something)
- **AI curriculum generation** — give it a learning goal and it generates a structured set of topics with prerequisites using `byLLM`
- **D3.js visualization** — interactive force-directed graph in the browser showing your topics and their connections

## Project Structure

```
├── models.jac          # Nodes (Topic, Path, Session, User) and edges (Prerequisite, RelatedTo)
├── auth.jac            # Register/login walkers
├── learning.jac        # Core logic: AI generation, SM-2 algorithm, recommendations
├── server.jac          # REST API walkers
├── main.jac            # CLI demo
├── hello.jac           # Quick start example from tutorial
├── index.html          # Web frontend with D3.js graph
└── requirements.txt    # Dependencies
```

## Setup

```bash
pip install jaclang
pip install -r requirements.txt
```

For AI features (topic generation via LLM), set your OpenAI API key:
```bash
export OPENAI_API_KEY="your-key-here"   # Linux/Mac
set OPENAI_API_KEY=your-key-here         # Windows CMD
$env:OPENAI_API_KEY="your-key-here"      # PowerShell
```
> The CLI demo (`jac run main.jac`) works without an API key — it uses hardcoded example data.

## How to Run

**CLI demo** (shows the full workflow — registration, AI topic generation, study sessions, SM-2 scheduling):
```bash
jac run main.jac
```

**Web interface:**
```bash
jac start server.jac
```
Then open `index.html` in your browser. Server runs on `http://localhost:8000`.

The server uses Jac's built-in auth system. Register via `POST /user/register` with `{"username": "...", "password": "..."}` to get a token, then pass it as `Authorization: Bearer <token>` to call walker endpoints.

## Custom Feature Details

### Knowledge Graph Structure
Topics aren't stored in a flat list — they're graph nodes connected by `Prerequisite` edges (with a `strength` property) and `RelatedTo` edges (with a `correlation` property). This means the app can do things like check if all prerequisites are met before recommending a topic, or traverse the graph to find the optimal next thing to study.

Relevant code: [models.jac](models.jac) for node/edge definitions, [learning.jac](learning.jac) for graph traversal logic.

### SM-2 Spaced Repetition
After each study session, you rate your understanding (1-5). The algorithm adjusts:
- **Interval**: How many days until next review (1 → 6 → interval × ease_factor)
- **Ease factor**: Gets harder or easier based on your ratings (min 1.3)
- **Mastery level**: Progresses through NOT_STARTED → LEARNING → PRACTICED → REVIEWING → MASTERED

If you score below 3, the interval resets. The formula: `EF' = EF + (0.1 - (5-q) × (0.08 + (5-q) × 0.02))`

This is implemented in the `log_session` walker in [learning.jac](learning.jac).

### AI Features
- `ai_generate_topics` — takes a learning goal string, uses `byLLM` to generate structured topic data, then creates nodes and prerequisite edges automatically
- `ai_suggest_next` — looks at mastery levels, prerequisite completion, and review urgency to recommend what to study next

### Web Frontend
The D3.js force-directed graph lets you drag nodes around, and colors indicate mastery level (gray → blue → green). You can log study sessions and see review schedules update in real time.

## Jac Features Used

- Custom nodes with typed properties (`Topic`, `Session`, `Path`, `User`)
- Custom edges with properties (`Prerequisite`, `RelatedTo`)
- Enums (`Difficulty`, `Mastery`)
- Graph traversal (`[-->]`, type filtering with `` (`?User) ``)
- `byLLM` for AI-generated structured data
- Multi-file project structure with imports
- REST API via `jac start`

## Testing

```bash
# CLI demo - generates topics, logs sessions, shows SM-2 scheduling
jac run main.jac

# Web server - interactive graph UI
jac start server.jac
```

## Resources

- [Jac Language Docs](https://docs.jaseci.org/)
- [Jaseci Tutorial](https://docs.jaseci.org/tutorials/)
- [SM-2 Algorithm](https://en.wikipedia.org/wiki/SuperMemo#Description_of_SM-2_algorithm)

---

**Repository**: https://github.com/peaceouty/EECS-449-Extra-Credit-Assignment1-AI-Study-Planner-with-Knowledge-Graph
