/// Localized text strings and labels used across the View360 Voice Call UI.
class View360CallStrings {
  /// Name or title of the AI voice agent.
  final String agentName;

  /// Label shown when call is connected.
  final String connectedLabel;

  /// Label shown while waiting for speech/agent response.
  final String listeningLabel;

  /// Main header question on the start call screen.
  final String haveAQuestion;

  /// Subtitle explanation on the start call screen.
  final String aiSupportText;

  /// Action button label to initiate a voice call.
  final String startVoiceChat;

  /// Header text when a call completes.
  final String callCompleted;

  /// Subtitle shown after call ends.
  final String thankYouSummary;

  /// Header text after feedback is submitted.
  final String feedbackReceived;

  /// Thank you message after feedback submission.
  final String thankYouImprovement;

  /// Rating prompt text.
  final String howWasExperience;

  /// Hint text for feedback input field.
  final String feedbackHint;

  /// Done/Submit button label.
  final String done;

  /// Label for starting a new call after ending one.
  final String startNewCall;

  /// Label displayed on bubbles representing the user's transcript.
  final String you;

  /// Label displayed on bubbles representing the agent's transcript.
  final String agent;

  /// Creates a [View360CallStrings] instance with customizable labels.
  const View360CallStrings({
    this.agentName = 'View360 Voice AI',
    this.connectedLabel = 'Connected',
    this.listeningLabel = 'Listening for agent...',
    this.haveAQuestion = 'Have a Question?',
    this.aiSupportText = 'Talk to our AI voice assistant for instant support.',
    this.startVoiceChat = 'Start Voice Chat',
    this.callCompleted = 'Call Completed',
    this.thankYouSummary = 'Thank you for your call. Here is a summary.',
    this.feedbackReceived = 'Feedback Received',
    this.thankYouImprovement = 'Thank you! Your feedback helps us improve.',
    this.howWasExperience = 'How was your experience?',
    this.feedbackHint = 'Add feedback...',
    this.done = 'Done',
    this.startNewCall = 'Start New Call',
    this.you = 'YOU',
    this.agent = 'AGENT',
  });
}

