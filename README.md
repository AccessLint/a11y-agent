# A11y Agent

A11y Agent is a multi-turn AI agent that supports developers in remediating React templates. It uses rules from `eslint-plugin-jsx-a11y` from a [Sublayer](Sublayerapp/Sublayer) agent to perform iterative fixes, with user input along the way.

A11y Agent is unique in the way it combines traditional programming, AI prompting, and human judgement to accelerate the accessibility remediation process.

## Usage

Run the CLI command and follow the prompts:

        ruby a11y_agent.rb /path/to/file.[jsx|tsx]
