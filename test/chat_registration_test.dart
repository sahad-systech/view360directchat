import 'package:flutter_test/flutter_test.dart';
import 'package:view360directchat/view360directchat.dart';

void main() {
  group('ChateRegisterResponse queue logic & parsing', () {
    test(
      'successful direct assignment sets success: true and isInQueue: false',
      () {
        final json = {
          'is_queue': false,
          'message': 'Connected directly to agent',
          'customer': {'id': 123},
        };

        final response = ChateRegisterResponse.fromJson(json);

        expect(response.success, isTrue);
        expect(response.isInQueue, isFalse);
        expect(response.message, 'Connected directly to agent');
      },
    );

    test(
      'successful direct assignment without message defaults gracefully',
      () {
        final json = {
          'is_queue': false,
          'customer': {'id': 124},
        };

        final response = ChateRegisterResponse.fromJson(json);

        expect(response.success, isTrue);
        expect(response.isInQueue, isFalse);
        expect(response.message, isNull);
      },
    );

    test(
      'successful queue assignment sets success: true and isInQueue: true',
      () {
        final json = {
          'is_queue': true,
          'message': 'All agents are busy, placed in waiting queue',
          'customer': {'id': 125},
        };

        final response = ChateRegisterResponse.fromJson(json);

        expect(response.success, isTrue);
        expect(response.isInQueue, isTrue);
        expect(
          response.message,
          'All agents are busy, placed in waiting queue',
        );
      },
    );

    test(
      'successful queue assignment uses default message when none provided',
      () {
        final json = {
          'is_queue': true,
          'customer': {'id': 126},
        };

        final response = ChateRegisterResponse.fromJson(json);

        expect(response.success, isTrue);
        expect(response.isInQueue, isTrue);
        expect(response.message, 'Agent not available');
      },
    );

    test(
      'failed registration via factory sets success: false and isInQueue: false',
      () {
        final response = ChateRegisterResponse.error(
          'Customer email or phone is required',
        );

        expect(response.success, isFalse);
        expect(response.isInQueue, isFalse);
        expect(response.message, 'Customer email or phone is required');
      },
    );

    test('failed registration from API json with status: false', () {
      final json = {'status': false, 'message': 'Invalid Application ID'};

      final response = ChateRegisterResponse.fromJson(json);

      expect(response.success, isFalse);
      expect(response.message, 'Invalid Application ID');
    });

    test('failed registration from API json with success: false', () {
      final json = {'success': false, 'message': 'Tenant account suspended'};

      final response = ChateRegisterResponse.fromJson(json);

      expect(response.success, isFalse);
      expect(response.message, 'Tenant account suspended');
    });

    test(
      'caller conditional branch routes direct, queue, and error correctly',
      () {
        final directAssignment = ChateRegisterResponse.fromJson({
          'is_queue': false,
        });
        final queueAssignment = ChateRegisterResponse.fromJson({
          'is_queue': true,
          'message': 'Waiting for agent',
        });
        final registrationError = ChateRegisterResponse.error(
          'Validation error',
        );

        String routeResponse(ChateRegisterResponse res) {
          if (res.success) {
            if (res.isInQueue == true) {
              return 'in_queue';
            } else {
              return 'direct_chat';
            }
          } else {
            return 'error: ${res.message}';
          }
        }

        expect(routeResponse(directAssignment), 'direct_chat');
        expect(routeResponse(queueAssignment), 'in_queue');
        expect(routeResponse(registrationError), 'error: Validation error');
      },
    );
  });
}
