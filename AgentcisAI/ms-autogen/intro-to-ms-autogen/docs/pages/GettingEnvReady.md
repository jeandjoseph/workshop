## 🛠️ Getting Your Environment Ready

🧰 Before diving into the workshop, let’s set up your Python environment and install the required libraries.

🧑‍💻 **Prerequisite:** 
1. Make sure you have [Visual Studio Code (VS Code)](https://code.visualstudio.com/download) or any similar IDE and [Python](https://www.python.org/downloads/) installed before proceeding with the virtual environment setup.
    * If the link doesn’t work, you can download VS Code here: https://code.visualstudio.com/download and https://www.python.org/downloads/

2. You need an Azure OpenAI or OpenAI subscription to deploy one or more types of generative AI models. Alternatively, you’re free to download a model locally if you prefer managing it yourself.

    - For the Microsoft Azure platform, please follow these instructions:
        1. Sign up for a [free subscription](https://azure.microsoft.com/en-us/) or use your existing Azure subscription.
        2. Create an [AI Foundry](https://ai.azure.com/) workspace to manage and host your models.
        3. Deploy a model of your choice.  
            - For this workshop, we’re using **gpt-4.1-nano** to optimize for cost.
            - You can browse other models in the AI Foundry interface based on your needs.
        4. Copy, and paste the following details into a plain text file:
            - API endpoint URL
            - API key
            - Model version
        5. Create a new folder (for instance, name it `AIAgent`) to keep your project structure clean and secure.
        6. Save the text file as **.env** (environment configuration file) inside the newly created folder.
---
## ⚙️ Environment Setup Overview

To get started, you'll need to install and configure **two distinct environments**:

1. 🌐 [Microsoft AutoGen for Azure OpenAI API](../pages/InstallAutoGenAPI.md)  
   – Set up the core AutoGen libraries for API-based agent orchestration.

2. 🧪 [Microsoft AutoGen Studio](../pages/InstallAutogenStudio.md)  
   – Configure the Studio interface for designing, testing, and managing agents and workflows.

> ✅ Complete both installations before proceeding to hands-on tasks or demos.



🌟 Proceed to the **Next Page** to dive into the core concepts of [Microsoft Autogen](https://microsoft.github.io/autogen/stable/index.html)


<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/autogencomponents.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/DirectHumanInteraction.md">Next → Page</a>
    </td>
  </tr>
</table>
