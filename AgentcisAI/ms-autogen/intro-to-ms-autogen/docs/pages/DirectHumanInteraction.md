#
<h1 style="color:white; text-align:center;">
  Enables a human to act as an agent
</h1>
This script demonstrates one of the simplest and most direct ways to leverage Microsoft AutoGen by enabling a human to interact directly with an agentic framework without needing a complex orchestration layer or multi-agent setup.

### 🧠 What It Does
It sets up a basic loop where a human types a message, and that message is sent to an AI model (hosted via Azure OpenAI) using the AutoGen-compatible **AzureOpenAIChatCompletionClient**. The model responds, and the human sees the output just like chatting with an assistant.

### 🧩 Why It’s Agentic
In the AutoGen ecosystem, an agent is any entity that can send and receive messages, make decisions, and take actions. In this case:
- The human is acting as an agent by initiating messages and interpreting responses.
- The AI model is another agent, responding to the human’s input.
- The script acts as a bridge between the two, using AutoGen’s building blocks (UserMessage, ChatCompletionClient) to facilitate the interaction.

### 🔄 How It Works
- **Environment Setup**: Loads credentials and model info from .env.
- **Client Initialization**: Uses AzureOpenAIChatCompletionClient to connect to the Azure-hosted model.
- **Message Exchange**: Wraps the human’s input in a UserMessage and sends it to the model.
- **Loop**: Keeps the conversation going until the user types "done".

### 🧪 Why This Matters
This pattern is ideal for:
* Prototyping agent behaviors.
* Testing model responses in a controlled loop.
* Embedding human-in-the-loop workflows where a person guides or supervises the AI.


### 🛠️ Before We Execute the Script: Key Concepts to Understand
This script is a foundational example of how to use Microsoft AutoGen to let a human directly interact with an agentic framework. Before diving into execution, let’s break down a few important components that make this possible:

**model_client = AzureOpenAIChatCompletionClient(...)**: This is the core client that connects your script to Azure OpenAI’s chat model. It’s part of the autogen_ext package and is designed to be AutoGen-compatible. It handles:
  * Authentication using your Azure credentials.
  * Sending and receiving messages in a structured, agent-like format.
  * Managing the lifecycle of the connection (e.g., opening and closing sessions).

This client is what allows your script to behave like an agent interface you send a message, and it returns a response from the model.

**UserMessage from autogen_core.models**: This class wraps the human’s input into a structured message object. It includes:
    - The message content (what the user says).
    - The source, which in this case is "user", indicating that the message is coming from a human agent.

This structure is essential for AutoGen’s agent framework, which relies on message objects to track and manage interactions between agents.

**await model_client.create([UserMessage(content=user_message, source="user")])**: This line sends the wrapped message to the model asynchronously and waits for a response. It’s the moment of interaction between the human and the AI agent.
* **UserMessage(...)**: This wraps the human's input into a structured message object that AutoGen agents understand.
* **content=user_message**: This is the actual text the human types.
* **source="user"**: This explicitly identifies the origin of the message as a human agent. In AutoGen, every message includes a source field to track which agent (human, LLM, or tool) sent it. By setting source="user", you're telling the system:
    - “This message comes from a human agent participating in the agent loop.”
* **await model_client.create([...])**: This sends the message to an LLM agent (like GPT hosted on Azure) and waits for its response asynchronously.

#### ⚙️ Steps to Run `HumanAndAIAgent.py`
1. Activate your Python virtual environment. Make sure it's up and running without issues.
2. Copy the code below into a text editor. You can use something simple like Notepad.

```python
import os
from dotenv import load_dotenv
# Imports the Azure OpenAI Chat Completion Client from the autogen_ext.models.openai module
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
# Imports the UserMessage class from the autogen_core.models module
from autogen_core.models import UserMessage
# Asynchronously imports the asyncio module to handle asynchronous operations
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
    result = await model_client.create([
        UserMessage(content=user_message, source="user")
    ])

    # Asynchronously close the model client, releasing any resources it holds
    await model_client.close()
    print(result.content)

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

```

3. Save the file as `HumanAndAIAgent.py`. Choose a folder where your virtual environment can easily access it.
4. Execute the script within your virtual environment context. Open a terminal or command prompt and run:
```bash
 python HumanAndAIAgent.py
```

5. When prompted, type `What is Power BI?` and feel free to experiment with different prompts.

🧩 Explanation this piece of code

```python
result = await model_client.create([
    UserMessage(content=user_message, source="user")
])
```
this snippet creates an asynchronous user message exchange with a model client: `model_client.create([...])` sends the message, wrapped as a `UserMessage` with content containing the user's input and `source="user"` indicating the origin; the await keyword ensures the code waits for the model’s response before continuing, and that response is stored in result, which includes structured metadata like role, content, and timestamp, all part of AutoGen's modular agent communication flow.

we also used `asyncio.run()` which is a synchronous entry point that executes an asynchronous coroutine. In Microsoft AutoGen 0.4+, the core distinction between asynchronous and synchronous execution lies in how agents (humans, LLMs, or tools) interact and how tasks are orchestrated in the agent loop. We used `asyncio.run()` as a synchronous entry point to execute async coroutines, it blocks until completion—while `asyncio.run_stream()` supports streaming interactions with agents, enabling async updates during task progression.

### 🔄 Synchronous Interaction
- **Blocking behavior**: Each agent waits for the previous one to finish before proceeding.
- **Simpler control flow**: Easier to reason about, especially in linear or sequential workflows.
- **Use case**: Ideal for simple, step-by-step interactions where timing and concurrency are not critical.
- **Example**: A human sends a message, waits for the LLM to respond, then replies—one message at a time.

### ⚡ Asynchronous Interaction
- **Non-blocking behavior**: Agents can operate independently and concurrently.
- **More scalable**: Supports parallel task execution, background processing, and real-time responsiveness.
- **Use case**: Essential for multi-agent collaboration, tool invocation, or when integrating with APIs or external systems.
- **Example**: While one agent is waiting for a tool to return data, another agent can continue processing or responding.

Click on the **Next Page** to begin demonstrating how agents interact with one another. We'll focus on fixed-turn conversations.

<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/InstallAutoGenAgentChatAPI.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/AgentRoundRobinGroupChat.md">Next Page →</a>
    </td>
  </tr>
</table>
