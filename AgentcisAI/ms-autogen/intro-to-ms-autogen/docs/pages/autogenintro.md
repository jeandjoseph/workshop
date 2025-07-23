<h2 style="color:white; text-align:center;">
What is Microsoft Autogen Framework?
</h2>
<a href="https://microsoft.github.io/autogen/stable/" target="_blank">Microsoft AutoGen</a> 0.4+ Core Concept It’s a framework for building multi-agent systems using large language models (LLMs). Think of it as a way to make multiple AIs collaborate intelligently, each agent has its own role, tools, and communication rules. They can plan tasks together, share results, and adapt dynamically, without micromanagement from the user.


### 🔧 Key ideas:

- **Agent Autonomy:** Agents make decisions, ask each other questions, and solve problems cooperatively.

- **Multi-agent Coordination:** It’s not just one AI-teams of AIs working together.

- **Configurable Skills & Tools:** Each agent can use APIs, code, or search as needed.

- **Human-in-the-loop Optional:** You can guide them or let them run independently.

It's like giving AI agents personalities and letting them talk to each other to get stuff done efficiently.

## AutoGen v0.4+ Architecture Overview
![](https://github.com/jeandjoseph/workshop/blob/main/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/AutoGeArchitecture.png)

# 🚀 Microsoft AutoGen v0.4+ Overview

## ⚙️ Core Framework
AutoGen is a Python-based framework for building **multi-agent LLM applications**.

- **Core**: Agent classes, messaging protocols, task orchestration.
- **AgentChat**: Multi-agent interactions with delegated goals, tools, and memory.
- **Extensions**: Custom tools, memory modules, evaluators, and protocols.
- **Your Extensions**: Integrate domain logic, APIs, or external services.

## 🧠 Developer Tools
Accelerate design, testing, and deployment.

- **Studio**: Visual interface for building agents and workflows.
- **Bench**: CLI for scripted agent sessions and integration testing.

## 📦 Apps Layer
Run production-grade agent apps.

- **Magnetic-One**: Microsoft sample app using advanced agent orchestration.
- **Your Custom App**: Your tailored agent-based solutions, built atop the framework.

## 🧩 Design Principles

| Principle               | Description                                                 |
|------------------------|-------------------------------------------------------------|
| Agent-centric           | Each agent has autonomy, goals, tools, and memory.         |
| Multi-agent orchestration | Agents collaborate to solve tasks via chat-like protocols. |
| Extensible              | Easily add or swap modules and integrations.               |
| Transparent             | Trace logs and hooks for debugging and auditability.        |
| LLM-agnostic            | Works with OpenAI, Azure OpenAI, local models, and more.   |

---

🌟 Proceed to the **Next Page** to dive into the core components of Microsoft Autogen

<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="EnvConfiguration.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/autogencomponents.md">Next → Page</a>
    </td>
  </tr>
</table>
