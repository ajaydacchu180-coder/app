import 'dart:async';

/// HRChatbotService provides an intelligent HR assistant.
///
/// This addresses the Project Manager's requirement for:
/// - 24/7 self-service HR assistant
/// - Answer policy questions
/// - Process simple requests (leave, queries)
/// - Onboarding assistance
class HRChatbotService {
  final List<ChatMessage> _conversationHistory = [];

  // Knowledge base for common HR queries
  final Map<String, HRKnowledgeItem> _knowledgeBase = {
    'leave_types': HRKnowledgeItem(
      keywords: [
        'leave',
        'types',
        'vacation',
        'sick',
        'annual',
        'personal',
        'maternity',
        'paternity'
      ],
      response: '''We offer the following leave types:
      
📅 **Annual Leave**: 20 days per year
🏥 **Sick Leave**: 10 days per year
👤 **Personal Leave**: 5 days per year
👶 **Maternity Leave**: 26 weeks (as per law)
👨‍👧 **Paternity Leave**: 2 weeks

To apply for leave, go to Leave Management in the app.''',
      category: HRCategory.leave,
    ),
    'leave_balance': HRKnowledgeItem(
      keywords: ['leave', 'balance', 'remaining', 'how many', 'days left'],
      response: '''To check your leave balance:
      
1️⃣ Open the app
2️⃣ Go to **Leave Management**
3️⃣ View your balance at the top

Your balance updates automatically when leave is approved.''',
      category: HRCategory.leave,
      requiresData: true,
    ),
    'apply_leave': HRKnowledgeItem(
      keywords: ['apply', 'leave', 'request', 'submit', 'take off', 'day off'],
      response: '''To apply for leave:
      
1️⃣ Go to **Leave Management**
2️⃣ Tap **Apply for Leave**
3️⃣ Select leave type, dates, and reason
4️⃣ Submit for approval

Your manager will be notified automatically. You'll receive notification once approved.''',
      category: HRCategory.leave,
      canTriggerAction: true,
      actionType: 'APPLY_LEAVE',
    ),
    'payslip': HRKnowledgeItem(
      keywords: ['payslip', 'salary', 'pay', 'wage', 'compensation', 'slip'],
      response: '''To view your payslip:
      
1️⃣ Go to **Payslip**
2️⃣ Select month/year
3️⃣ View earnings and deductions breakdown

You can download PDF copies for your records.''',
      category: HRCategory.payroll,
      requiresData: true,
    ),
    'attendance': HRKnowledgeItem(
      keywords: [
        'attendance',
        'clock',
        'check in',
        'check out',
        'punch',
        'time'
      ],
      response: '''For attendance:
      
**Clock In/Out Methods:**
📱 Use the app - tap Clock In/Out
📷 Scan QR code at office entrance
📍 Auto clock-in when entering geofenced office area

**View History:**
Go to Attendance → History to see your records.''',
      category: HRCategory.attendance,
    ),
    'work_hours': HRKnowledgeItem(
      keywords: [
        'work hours',
        'working hours',
        'office time',
        'timing',
        'schedule'
      ],
      response: '''**Standard Work Hours:**
      
🕘 **Start Time**: 9:00 AM
🕕 **End Time**: 6:00 PM
⏱️ **Daily Hours**: 8 hours
🍽️ **Lunch Break**: 1 hour (1:00 PM - 2:00 PM)

Flexible timing may apply based on department. Check with your manager.''',
      category: HRCategory.policy,
    ),
    'holidays': HRKnowledgeItem(
      keywords: [
        'holiday',
        'holidays',
        'public holiday',
        'company holiday',
        'off day'
      ],
      response: '''Our holiday calendar is available in the app!
      
Go to **Leave Management → Holiday Calendar** to see all upcoming company holidays.

We observe all national holidays plus additional company-specific days.''',
      category: HRCategory.policy,
    ),
    'wfh': HRKnowledgeItem(
      keywords: ['work from home', 'wfh', 'remote', 'home office', 'hybrid'],
      response: '''**Work From Home Policy:**
      
📍 Hybrid model: 3 days office, 2 days WFH
📅 WFH days must be pre-approved
📝 Apply through Leave Management → Work From Home

Requirements:
• Stable internet connection
• Available during work hours
• Attend all scheduled meetings''',
      category: HRCategory.policy,
    ),
    'expense': HRKnowledgeItem(
      keywords: ['expense', 'reimbursement', 'claim', 'receipt'],
      response: '''**Expense Reimbursement Process:**
      
1️⃣ Keep all original receipts
2️⃣ Submit via Expenses in the app
3️⃣ Attach receipt photos
4️⃣ Add expense category and description
5️⃣ Submit for approval

Reimbursements are processed within 5 business days of approval.''',
      category: HRCategory.expense,
    ),
    'password': HRKnowledgeItem(
      keywords: [
        'password',
        'reset',
        'forgot',
        'change password',
        'login issue'
      ],
      response: '''**Password Help:**
      
**To change password:**
Profile → Change Password

**Forgot password?**
Tap "Forgot Password" on login screen

**Requirements:**
• Minimum 8 characters
• At least 1 uppercase, 1 lowercase, 1 number
• Change every 90 days recommended''',
      category: HRCategory.technical,
    ),
    '2fa': HRKnowledgeItem(
      keywords: ['2fa', 'two factor', 'authenticator', 'security code'],
      response: '''**Two-Factor Authentication (2FA):**
      
2FA adds an extra layer of security to your account.

**To Enable:**
Profile → Two-Factor Authentication → Enable

**How it works:**
1. Download Google Authenticator or Authy
2. Scan QR code shown in app
3. Enter 6-digit code to verify
4. Save backup codes securely''',
      category: HRCategory.technical,
    ),
    'benefits': HRKnowledgeItem(
      keywords: ['benefit', 'benefits', 'insurance', 'health', 'medical'],
      response: '''**Employee Benefits:**
      
💊 **Health Insurance**: Comprehensive coverage for you + family
🦷 **Dental**: Included in health plan
👁️ **Vision**: Annual eye checkup covered
🏋️ **Wellness**: Gym membership reimbursement (50%)
📚 **Learning**: Annual training budget ₹50,000
🎂 **Birthday Leave**: 1 extra day off on your birthday!''',
      category: HRCategory.benefits,
    ),
    'contact_hr': HRKnowledgeItem(
      keywords: [
        'contact',
        'hr',
        'human resources',
        'help',
        'speak to',
        'talk to'
      ],
      response: '''**Contact HR:**
      
📧 Email: hr@company.com
📞 Phone: +91 98765 43210
🕘 Available: Mon-Fri, 9 AM - 6 PM

For urgent matters, please call directly.

You can also raise a ticket through this chat for faster resolution.''',
      category: HRCategory.support,
      canTriggerAction: true,
      actionType: 'CREATE_TICKET',
    ),
    'onboarding': HRKnowledgeItem(
      keywords: [
        'new',
        'joining',
        'onboarding',
        'first day',
        'new employee',
        'starter'
      ],
      response: '''**Welcome to the team! 🎉**

**Your Onboarding Checklist:**
✅ Complete profile in the app
✅ Set up biometric login
✅ Enable 2FA for security
✅ Review company policies
✅ Complete compliance training
✅ Meet your team members
✅ Set up your workspace

Questions? I'm here to help 24/7!''',
      category: HRCategory.onboarding,
    ),
  };

  /// Process a user message and generate response
  Future<ChatbotResponse> processMessage(String userMessage) async {
    // Add to history
    _conversationHistory.add(ChatMessage(
      role: MessageRole.user,
      content: userMessage,
      timestamp: DateTime.now(),
    ));

    // Analyze intent
    final intent = _analyzeIntent(userMessage.toLowerCase());

    // Generate response based on intent
    ChatbotResponse response;

    if (intent != null) {
      response = ChatbotResponse(
        message: intent.response,
        category: intent.category,
        suggestedActions: _getSuggestedActions(intent),
        requiresData: intent.requiresData,
        actionType: intent.canTriggerAction ? intent.actionType : null,
      );
    } else {
      // Fallback response
      response = ChatbotResponse(
        message:
            '''I'm not sure I understood that. Here are some things I can help with:

📅 **Leave** - Balance, apply, types
💰 **Payroll** - Payslips, salary queries
⏰ **Attendance** - Clock in/out, history
📋 **Policies** - Work hours, WFH, benefits
🔐 **Account** - Password, 2FA, login issues
📞 **Support** - Contact HR

Try asking something like:
• "How do I apply for leave?"
• "What's my leave balance?"
• "Show my payslip"''',
        category: HRCategory.general,
        suggestedQueries: [
          'How do I apply for leave?',
          'Show my payslip',
          'Work from home policy',
          'Contact HR',
        ],
      );
    }

    // Add response to history
    _conversationHistory.add(ChatMessage(
      role: MessageRole.assistant,
      content: response.message,
      timestamp: DateTime.now(),
    ));

    return response;
  }

  /// Analyze user message to determine intent
  HRKnowledgeItem? _analyzeIntent(String message) {
    int bestScore = 0;
    HRKnowledgeItem? bestMatch;

    for (final item in _knowledgeBase.values) {
      int score = 0;
      for (final keyword in item.keywords) {
        if (message.contains(keyword)) {
          score += keyword.length; // Longer keywords = more specific match
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = item;
      }
    }

    // Require minimum score for a match
    return bestScore >= 4 ? bestMatch : null;
  }

  /// Get suggested follow-up actions
  List<SuggestedAction> _getSuggestedActions(HRKnowledgeItem item) {
    switch (item.category) {
      case HRCategory.leave:
        return [
          SuggestedAction(
            label: '📅 Apply for Leave',
            action: 'NAVIGATE',
            destination: '/leave/apply',
          ),
          SuggestedAction(
            label: '📊 Check Balance',
            action: 'NAVIGATE',
            destination: '/leave/balance',
          ),
        ];
      case HRCategory.payroll:
        return [
          SuggestedAction(
            label: '💰 View Payslip',
            action: 'NAVIGATE',
            destination: '/payslip',
          ),
        ];
      case HRCategory.attendance:
        return [
          SuggestedAction(
            label: '🕐 Clock In',
            action: 'CLOCK_IN',
            destination: null,
          ),
          SuggestedAction(
            label: '📋 View History',
            action: 'NAVIGATE',
            destination: '/attendance/history',
          ),
        ];
      case HRCategory.support:
        return [
          SuggestedAction(
            label: '📝 Create Support Ticket',
            action: 'CREATE_TICKET',
            destination: null,
          ),
          SuggestedAction(
            label: '📞 Call HR',
            action: 'CALL',
            destination: 'tel:+919876543210',
          ),
        ];
      default:
        return [];
    }
  }

  /// Get quick action suggestions based on time of day
  List<String> getQuickSuggestions() {
    final hour = DateTime.now().hour;

    if (hour < 10) {
      return [
        '⏰ Clock In',
        '📅 Today\'s Schedule',
        '📋 My Tasks',
      ];
    } else if (hour > 17) {
      return [
        '⏰ Clock Out',
        '📊 Today\'s Summary',
        '📅 Tomorrow\'s Schedule',
      ];
    } else {
      return [
        '📅 Leave Balance',
        '💰 View Payslip',
        '📞 Contact HR',
      ];
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Get conversation history
  List<ChatMessage> getHistory() => List.unmodifiable(_conversationHistory);
}

// =================== Data Models ===================

enum HRCategory {
  leave,
  payroll,
  attendance,
  policy,
  expense,
  technical,
  benefits,
  support,
  onboarding,
  general,
}

class HRKnowledgeItem {
  final List<String> keywords;
  final String response;
  final HRCategory category;
  final bool requiresData;
  final bool canTriggerAction;
  final String? actionType;

  HRKnowledgeItem({
    required this.keywords,
    required this.response,
    required this.category,
    this.requiresData = false,
    this.canTriggerAction = false,
    this.actionType,
  });
}

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatbotResponse {
  final String message;
  final HRCategory category;
  final List<SuggestedAction> suggestedActions;
  final List<String>? suggestedQueries;
  final bool requiresData;
  final String? actionType;

  ChatbotResponse({
    required this.message,
    required this.category,
    this.suggestedActions = const [],
    this.suggestedQueries,
    this.requiresData = false,
    this.actionType,
  });
}

class SuggestedAction {
  final String label;
  final String
      action; // NAVIGATE, CLOCK_IN, CLOCK_OUT, CREATE_TICKET, CALL, etc.
  final String? destination;

  SuggestedAction({
    required this.label,
    required this.action,
    this.destination,
  });
}
