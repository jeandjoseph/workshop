#
<h1 style="color:white; text-align:center;">
Getting Started with RoundRobinGroupChat in AutoGen 0.4+<br>
Structured Multi-Turn Conversations Made Simple
</h1>

This workshop script shows how two AI agents **Jean** and **Daniel** can take turns responding in a way that feels like a real conversation, using Microsoft AutoGen 0.4’s or latest RoundRobinGroupChat strategy to simulate a structured, back-and-forth dialogue.

#

In this part of the demo, we're working within a controlled conversation flow. Each agent gets a chance to speak, but only up to a predefined number of turns—set by the max_turns limit. Think of it as a structured debate where the clock is ticking and each round counts. It's designed to keep things focused, concise, and efficient while still showcasing the dynamic between the agents.

In Microsoft AutoGen 0.4 and later, the framework introduces agent selection strategies that determine how messages are routed among multiple agents. These strategies fall into two broad categories: deterministic and non-deterministic, each playing a crucial role in shaping how agentic AI systems behave. This demo focuses on deterministic strategies, where the flow of conversation is predefined making `RoundRobinGroupChat` the ideal choice.

### 🔁 RoundRobinGroupChat – Deterministic
- **How it works**: Agents take turns in a fixed, circular order.
- **Behavior**: Every agent gets a chance to respond in sequence, and each response is broadcast to all other agents.
- **Use case**: Ideal for structured collaboration where each agent contributes equally and context is shared.
- **Key trait**: Deterministic — the order of agent turns is predictable and repeatable.
- **Example**: Agent A → Agent B → Agent C → Agent A...

This is useful when you want fairness and transparency in agent participation.

Our focus is on building a **deterministic** Microsoft AutoGen agent, which necessitates using the `RoundRobinGroupChat` to ensure predictable, sequential message passing among agents. This structure avoids randomness in agent selection, aligning with our deterministic design goals. 

🧠 **Key Takeaway:** Async Execution Paths Matter

In `asyncio`, we distinguish between `run()` and `run_stream()`:
- `run()` executes the full conversation flow and returns only the final result.
- `run_stream()` yields intermediate steps in real time, ideal for debugging, monitoring, or building reactive interfaces.
- **Note:** Choosing between the two depends on whether you need post-hoc results or granular, step-by-step visibility during execution.

🧩 **Related Constructs:** 
- `AssistantAgent`: A modular, autonomous agent powered by a language model configured with tools and a system_message to perform specialized roles in orchestration.
- `team.run()`: Executes the full agentic workflow asynchronously and returns the final result (TaskResult) without streaming intermediate messages.
- `max_turns`: Limits the number of exchanges in a group chat to prevent infinite loops or overly long conversations.


#### ✅ Steps to complete this demo:
1. Activate your [Python virtual](../pages/CreatePythonVirtualEnv.md) environment. Make sure it's up and running without issues.
2. Copy the code below into a text editor. You can use something simple like Notepad.

````bash
import os
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
import asyncio


# Load environment variables from .env file
load_dotenv()

# Retrieve environment variables
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# Print retrieved environment variables
print(azure_openai_endpoint)
print(azure_openai_model_name)
print(azure_openai_api_version)


# Define an async function to interact with the model client
async def interact_with_model(user_message):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    # Create a user message and get the response from the model client
    subject = "clean datasets in the machine learning process"
    Jean = AssistantAgent(
     name="Jean",
        model_client=model_client,
        system_message=(
            "You are Jean, a Data Engineer. "
            "Your task is to clearly and very concisely explain the importance of {subject}. "
            "Focus on being very brief, direct, and informative. "
            "Make sure you introduce yourself as Jean, a Data Engineer, at only the start of the first conversation. "
     ),
    )


    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            "You are Daniel, an AI Engineer. "
            "Begin conversations by discussing anout the {subject}. "
            "Be very concise and focus specifically on data cleansing and feature engineering. "
            "Make sure you introduce yourself as Daniel, an AI Engineer, at only the start of the first conversation."
     ),
    )

    team = RoundRobinGroupChat(
        participants=[Daniel, Jean],
        max_turns=3,
    )
   
    res= await team.run(task=user_message)
    
    for message in res.messages:
        print('='*100)
        print(f"{message.source}: {message.content}")

# Loop to get user input until "done" is typed
def main():
    while True:
        user_input = input("Enter your message (type 'done' to exit): ").strip()
        if user_input.lower() == "done":
            break
        asyncio.run(interact_with_model(user_input))

# Run the main loop
if __name__ == "__main__":
    main()
````

3. Save the file as `autogen_fixed_turn_demo_run.py`. Choose a folder where your virtual environment can easily access it.
5. Run the script using the terminal: Observe how the agents communicate in a multi-turn conversation with deterministic sequencing.
```python
python autogen_fixed_turn_demo_run.py
```
6. Wait until the execution is completed

Notice that in a RoundRobinGroupChat, the order of agents in the participants list directly determines the turn-taking sequence. For example, if `participants = [Daniel, Jean]`, Daniel will respond first, followed by Jean, then back to Daniel, and so on alternating strictly in that order. Changing it to `participants = [Jean, Daniel]` means Jean takes the first turn, followed by Daniel, and the cycle continues from there.

🔁 Here’s an example: Replace your original Team participant setup with the script below and observe how the listed order defines the flow of the conversation:

```python
team = RoundRobinGroupChat(
    participants=[Daniel, Jean],
    max_turns=3,
)
```
Once complete, we’ll explore the run_stream() generator for real-time interaction and step-by-step output.

We just explored `asyncio.run()`, which waits for the entire conversation to finish before showing results. Now, let’s shift to `run_stream()`. The key difference is that `run_stream()` is an async generator it lets us observe the conversation step by step as it unfolds. Unlike regular functions that reset after returning, generators remember where they left off and resume from the last yield, making them perfect for interactive, real-time experimentation.

When using `run_stream()`, make sure to import `TaskResult` with `from autogen_agentchat.base import TaskResult`. This is essential because each step in the stream yields a TaskResult object, which holds the intermediate output of the conversation. Without this import, you won’t be able to properly access or interpret the streamed results as they come in.

### 🔄 `run_stream()`. Code Update Summary

In this version, we made two key changes:

1️⃣ Replaced the blocking run() call with the streaming run_stream() to observe the conversation step by step and capture real-time outputs. 
2️⃣ TaskResult indicates why the chat stopped (e.g. max_turns, tool_use_limit) and optionally includes final results for post-processing.

```python
# ❌ Old approach from above scripts
res = await team.run(task=user_message)
for message in res.messages:
    print('='*100)
    print(f"{message.source}: {message.content}")
`````

## ✅ New approach using run_stream
```python
async for res in team.run_stream(task=user_message):
    print('='*100)
    if isinstance(res, TaskResult):
        print(f'Stopping reason: {res.stop_reason}')
    else:
        print(f'{res.source}: {res.content}')
`````

2️⃣ 🧹 Removed the looped conversation logic to focus on a single, streamable interaction for clarity and experimentation.

````python
import os
import asyncio
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.base import TaskResult

# Load environment variables from .env file
load_dotenv()

# Retrieve environment variables
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# Print retrieved environment variables
print("Endpoint:", azure_openai_endpoint)
print("Model:", azure_openai_model_name)
print("API Version:", azure_openai_api_version)

# Define an async function to interact with the model client
async def run_ai_agent_debate(user_message):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    subject = "clean datasets in the machine learning process"

    Jean = AssistantAgent(
        name="Jean",
        model_client=model_client,
        system_message=(
            f"You are Jean, a Data Engineer. "
            f"Your task is to clearly and very concisely explain the importance of {subject}. "
            f"Focus on being very brief, direct, and informative. "
            f"Make sure you introduce yourself as Jean, a Data Engineer, at only the start of the first conversation."
        ),
    )

    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            f"You are Daniel, an AI Engineer. "
            f"Begin conversations by discussing about the {subject}. "
            f"Be very concise and focus specifically on data cleansing and feature engineering. "
            f"Make sure you introduce yourself as Daniel, an AI Engineer, at only the start of the first conversation."
        ),
    )

    team = RoundRobinGroupChat(
        participants=[Daniel, Jean],
        max_turns=3,
    )

    async for res in team.run_stream(task=user_message):
        print('-' * 20)
        if isinstance(res, TaskResult):
            print(f'Stopping reason: {res.stop_reason}')
        else:
            print(f'{res.source}: {res.content}')

# Run the main loop
if __name__ == "__main__":
    user_message = input("Enter your message (type 'done' to exit): ").strip()
    if user_message.lower() != 'done':
        asyncio.run(run_ai_agent_debate(user_message))
````

### 👀 Observation During `run_stream()` Execution

Notice that during execution with `run_stream()`, we can observe the conversation unfold **step by step** in real time. Each message is streamed as it’s generated, allowing us to monitor the interaction live—unlike `run()`, which only shows the full conversation after it completes. This makes `run_stream()` ideal for debugging, experimentation, and interactive applications.


### ✨ Share Your Experience

We hope this demo helped you understand how Microsoft AutoGen 0.4 enables structured, realistic conversations between AI agents. If you found this experience insightful or enjoyable, feel free to leave a comment and share your thoughts—your feedback helps us improve and shape future workshops!


<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/DirectHumanInteraction.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/DirectAgentInteractionMultiTurnDynamicTermination.md">Next Page →</a>
    </td>
  </tr>
</table>
