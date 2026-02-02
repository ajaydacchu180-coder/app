import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_attendance/src/services/hr_chatbot_service.dart';

void main() {
  group('HRChatbotService', () {
    late HRChatbotService service;

    setUp(() {
      service = HRChatbotService();
    });

    tearDown(() {
      service.clearHistory();
    });

    group('processMessage', () {
      test('should respond to leave-related queries', () async {
        final response =
            await service.processMessage('How do I apply for leave?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.leave));
      });

      test('should respond to leave balance queries', () async {
        final response =
            await service.processMessage('What is my leave balance?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.leave));
      });

      test('should respond to payslip queries', () async {
        final response =
            await service.processMessage('Where can I see my payslip?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.payroll));
      });

      test('should respond to attendance queries', () async {
        final response = await service.processMessage('How do I clock in?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.attendance));
      });

      test('should respond to work hours queries', () async {
        final response =
            await service.processMessage('What are the working hours?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.policy));
      });

      test('should respond to WFH policy queries', () async {
        final response = await service.processMessage('Can I work from home?');

        expect(response.message, isNotEmpty);
        expect(response.message.toLowerCase(), contains('work from home'));
      });

      test('should respond to benefits queries', () async {
        final response =
            await service.processMessage('What benefits do I get?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.benefits));
      });

      test('should respond to password queries', () async {
        final response =
            await service.processMessage('How do I reset my password?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.technical));
      });

      test('should respond to 2FA queries', () async {
        final response =
            await service.processMessage('How do I enable two factor?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.technical));
      });

      test('should respond to contact HR queries', () async {
        final response = await service.processMessage('How can I contact HR?');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.support));
      });

      test('should respond to onboarding queries', () async {
        final response = await service.processMessage('I am a new employee');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.onboarding));
      });

      test('should provide fallback for unknown queries', () async {
        final response =
            await service.processMessage('xyz123 random gibberish');

        expect(response.message, isNotEmpty);
        expect(response.category, equals(HRCategory.general));
        expect(response.suggestedQueries, isNotEmpty);
      });

      test('should include suggested actions for leave queries', () async {
        final response =
            await service.processMessage('How do I apply for leave?');

        expect(response.suggestedActions, isNotEmpty);
        expect(
          response.suggestedActions.any((a) => a.label.contains('Leave')),
          isTrue,
        );
      });

      test('should include suggested actions for attendance queries', () async {
        final response = await service.processMessage('clock in');

        expect(response.suggestedActions, isNotEmpty);
      });

      test('should retain conversation history', () async {
        await service.processMessage('Hello');
        await service.processMessage('How are you?');

        final history = service.getHistory();

        expect(history.length, equals(4)); // 2 user + 2 assistant
      });
    });

    group('getQuickSuggestions', () {
      test('should return non-empty suggestions', () {
        final suggestions = service.getQuickSuggestions();

        expect(suggestions, isNotEmpty);
        expect(suggestions.length, greaterThanOrEqualTo(3));
      });
    });

    group('clearHistory', () {
      test('should clear conversation history', () async {
        await service.processMessage('Hello');
        expect(service.getHistory(), isNotEmpty);

        service.clearHistory();
        expect(service.getHistory(), isEmpty);
      });
    });
  });

  group('Data Models', () {
    group('ChatMessage', () {
      test('should create user message correctly', () {
        final message = ChatMessage(
          role: MessageRole.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        );

        expect(message.role, equals(MessageRole.user));
        expect(message.content, equals('Hello'));
      });

      test('should create assistant message correctly', () {
        final message = ChatMessage(
          role: MessageRole.assistant,
          content: 'Hi there!',
          timestamp: DateTime.now(),
        );

        expect(message.role, equals(MessageRole.assistant));
      });
    });

    group('ChatbotResponse', () {
      test('should store response data correctly', () {
        final response = ChatbotResponse(
          message: 'This is a response',
          category: HRCategory.leave,
          suggestedActions: [
            SuggestedAction(
              label: 'Apply Leave',
              action: 'NAVIGATE',
              destination: '/leave',
            ),
          ],
        );

        expect(response.message, equals('This is a response'));
        expect(response.category, equals(HRCategory.leave));
        expect(response.suggestedActions.length, equals(1));
      });

      test('should handle suggested queries', () {
        final response = ChatbotResponse(
          message: 'How can I help?',
          category: HRCategory.general,
          suggestedQueries: ['Apply leave', 'View payslip'],
        );

        expect(response.suggestedQueries, isNotNull);
        expect(response.suggestedQueries!.length, equals(2));
      });
    });

    group('SuggestedAction', () {
      test('should create navigate action', () {
        final action = SuggestedAction(
          label: 'Apply Leave',
          action: 'NAVIGATE',
          destination: '/leave/apply',
        );

        expect(action.label, equals('Apply Leave'));
        expect(action.action, equals('NAVIGATE'));
        expect(action.destination, equals('/leave/apply'));
      });

      test('should create action without destination', () {
        final action = SuggestedAction(
          label: 'Clock In',
          action: 'CLOCK_IN',
          destination: null,
        );

        expect(action.destination, isNull);
      });
    });
  });

  group('HRCategory', () {
    test('should have all expected categories', () {
      expect(HRCategory.values, contains(HRCategory.leave));
      expect(HRCategory.values, contains(HRCategory.payroll));
      expect(HRCategory.values, contains(HRCategory.attendance));
      expect(HRCategory.values, contains(HRCategory.policy));
      expect(HRCategory.values, contains(HRCategory.expense));
      expect(HRCategory.values, contains(HRCategory.technical));
      expect(HRCategory.values, contains(HRCategory.benefits));
      expect(HRCategory.values, contains(HRCategory.support));
      expect(HRCategory.values, contains(HRCategory.onboarding));
      expect(HRCategory.values, contains(HRCategory.general));
    });
  });
}
