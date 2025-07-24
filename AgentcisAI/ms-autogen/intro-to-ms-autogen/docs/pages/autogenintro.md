<h2 style="color:white; text-align:center;">
What is Microsoft Autogen Framework?
</h2>
<a href="https://microsoft.github.io/autogen/stable/" target="_blank">Microsoft AutoGen</a> 0.4+ is a modular framework for building multi-agent systems using large language models (LLMs). It enables multiple AIs, each with defined roles, tools, and communication rules to collaborate, plan tasks, share results, and adapt dynamically with minimal user intervention. Whether via GUI or SDK, AutoGen provides composable building blocks for prototyping, orchestration, benchmarking, and deployment.

#### 🔧 Key ideas:

- **Agent Autonomy:** Agents make decisions, ask each other questions, and solve problems cooperatively.

- **Multi-agent Coordination:** It’s not just one AI-teams of AIs working together.

- **Configurable Skills & Tools:** Each agent can use APIs, code, or search as needed.

- **Human-in-the-loop Optional:** You can guide them or let them run independently.

It's like giving AI agents personalities and letting them talk to each other to get stuff done efficiently.

#### 🧠 Introduction to AutoGen 0.4 Ecosystem
The AG Ecosystem centers around three modular components: Developer Tools, Apps, and the Framework. Developers build and test agents using Bench and Studio, deploy them within customizable applications like Magnetic-One or custom apps, and extend capabilities through a layered framework consisting of AgentChat, Core, Extensions, and user-defined modules. This structure promotes a flexible, plug-and-play architecture for building scalable agentic AI workflows in Microsoft AutoGen.

![](https://github.com/jeandjoseph/workshop/blob/main/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/AutoGeArchitecture.png)


#### ⚙️ Core Framework
AutoGen is a Python-based framework for building **multi-agent LLM applications**.

- **Core**: Agent classes, messaging protocols, task orchestration.
- **AgentChat**: Multi-agent interactions with delegated goals, tools, and memory.
- **Extensions**: Custom tools, memory modules, evaluators, and protocols.
- **Your Extensions**: Integrate domain logic, APIs, or external services.

#### 🧠 Developer Tools
Accelerate design, testing, and deployment.

- 🧪 [Studio](https://microsoft.github.io/autogen/stable/user-guide/autogenstudio-user-guide/index.html) (AutoGen Studio)
  - Low-code GUI for visualizing, composing, and deploying agent workflows
  - Features drag-and-drop teams, control graphs, real-time message inspection, and export options
  - Ideal for rapid prototyping and instructional demos


- 📊 Bench (AutoGen Bench)
  - Benchmarking suite for evaluating agents across tasks, models, and configurations
  - Includes scoring logic, task templates, and automation support
  - Useful for researchers and developers optimizing agent strategies


#### 📦 Apps Layer
Run production-grade agent apps.

- 🧭 4. [Magentic-One](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/magentic-one.html#)
  - Prebuilt agentic applications for web, file, and multimodal tasks
  - Demonstrates best practices for composability and integration
  - Useful as templates for real-world deployment and workflow inspiration

- **Your Custom App**: Your tailored agent-based solutions, built atop the framework.
  - Includes both the [Core API](https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/index.html) and [AgentChat](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/index.html) API
  - Supports agent creation, tool integration, messaging, memory, and control flow
  - Best suited for developers building custom agentic workflows programmatically

#### 🧩 Design Principles

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
      <a href="whatisagenticai.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/autogencomponents.md">Next → Page</a>
    </td>
  </tr>
</table>
