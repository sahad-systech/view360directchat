# view360directchat Example

This example demonstrates how to integrate and use the `view360directchat` Flutter package for real-time customer chat and LiveKit-powered AI Voice Calling.

## Running the Example

1. Ensure you have Flutter installed.
2. In the `example` directory, fetch the dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Features Demonstrated

- **Chat Registration**: Creating a customer chat session with View360 REST endpoints using `ChatService`.
- **AI Voice Call Screen**: Opening the pre-built `View360CallPage` connected to LiveKit WebRTC server with customizable theme and strings.
- **Activity Logging**: Capturing callback events and state transitions in real time.
