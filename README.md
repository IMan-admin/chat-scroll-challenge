# Chat Auto-Scroll Challenge

## Setup

1. Get a free Gemini API key from [ai.google.dev](https://ai.google.dev)
2. Run `flutter pub get`
3. Run `flutter run` (web, macOS, or any platform)
4. Enter your API key and start chatting

## Your Task

This app has scroll UX issues. Compare it against the reference implementation and fix them.

**Reference:** https://iman-admin.github.io/chat-scroll-demo/

Test these scenarios in the reference demo before you start coding. Start by sending a message that produces a long response to fill the screen (e.g. _"Write a detailed essay about the history of the internet"_). If the response is too short, send another one.

1. Send a message and let the response stream in.
2. While a response is streaming, scroll up manually.
3. While scrolled up, send a new message.
4. While a response is streaming, scroll back down to the bottom.

Your solution will be scored primarily on how closely it matches the reference. You are free to use any AI tools you'd like.

## How to Submit

1. Clone this repo into a **private** repository on your own GitHub account.
2. Implement your solution.
3. Deploy your solution to the web.
4. Update this README with:
   - The UX issues you identified and fixed.
   - Your deployed URL.
   - Include screen recordings for all five scenarios and the deployed URL below.
5. Add **IMan-admin** as a collaborator to your private repo.
6. Send us the link to your repo.


### Deployed URL

Replace the placeholder below with your live deployed app URL.
[Live Demo - Replace with your deployed URL](https://your-deployed-url.com)

### Screen Recordings
Replace each placeholder below with your submitted recording link.  
You must submit **all 4 recordings**.


- **Scenario 1 (Basic Auto-Scroll):** [Watch Recording - Replace with your Scenario 1 link](https://your-recording-link.com/scenario1)
- **Scenario 2 (Pause on Manual Scroll):** [Watch Recording - Replace with your Scenario 2 link](https://your-recording-link.com/scenario2)
- **Scenario 3 (Send While Scrolled Up):** [Watch Recording - Replace with your Scenario 3 link](https://your-recording-link.com/scenario3)
- **Scenario 4 (Resume Auto-Scroll After Scroll Down):** [Watch Recording - Replace with your Scenario 4 link](https://your-recording-link.com/scenario4)
 

## Evaluation Criteria

- Does each scenario work correctly in isolation?
- Do all four scenarios work together without regressions?
- Does the behavior match the reference demo?
- Is the code clean, testable, and well-separated?
