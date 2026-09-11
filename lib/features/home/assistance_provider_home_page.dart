import 'package:flutter/material.dart';

/// Home page shown to assistance providers (mechanic, tow truck, fuel
/// delivery, flat tire, battery boost) after they complete their profile.
///
/// Mirrors the driver HomePage's visual language (rounded white sheet
/// over a colored header, card shadows, same bottom-nav shell) but with
/// provider-relevant content: an online/offline toggle, today's stats,
/// and a recent job-request history.
class AssistanceProviderHomePage extends StatefulWidget {
  final String userName;
  final String profileImagePath;

  const AssistanceProviderHomePage({
    super.key,
    this.userName = 'Assistant',
    this.profileImagePath = '',
  });

  @override
  State<AssistanceProviderHomePage> createState() =>
      _AssistanceProviderHomePageState();
}

class _AssistanceProviderHomePageState
    extends State<AssistanceProviderHomePage> {
  // TODO: back this with the provider's real isAvailable field in
  // Firestore (see AssistanceProvider.isAvailable) instead of local state.
  bool _isOnline = true;

  // TODO: replace with real counts from today's completed/active jobs.
  final int _jobsToday = 3;
  final double _earningsToday = 4250; // in LKR, adjust formatting as needed.

  // TODO: replace with the provider's real recent job requests, most
  // recent first, fetched from Firestore.
  final List<_JobRequest> _recentRequests = const [
    _JobRequest(
      serviceLabel: 'Flat Tire Change',
      customerName: 'Nadeesha Perera',
      location: 'Nugegoda',
      time: 'Today, 2:40 PM',
      status: _JobStatus.completed,
      earnings: 1500,
    ),
    _JobRequest(
      serviceLabel: 'Battery Boost',
      customerName: 'Kasun Silva',
      location: 'Rajagiriya',
      time: 'Today, 11:05 AM',
      status: _JobStatus.completed,
      earnings: 1200,
    ),
    _JobRequest(
      serviceLabel: 'Tow Truck',
      customerName: 'Amaya Fernando',
      location: 'Battaramulla',
      time: 'Yesterday, 6:15 PM',
      status: _JobStatus.cancelled,
      earnings: 0,
    ),
    _JobRequest(
      serviceLabel: 'Mechanic',
      customerName: 'Ruwan Jayasuriya',
      location: 'Kotte',
      time: 'Yesterday, 9:30 AM',
      status: _JobStatus.completed,
      earnings: 2800,
    ),
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  void _setOnline(bool value) {
    setState(() => _isOnline = value);
    // TODO: persist to Firestore, e.g.
    // FirebaseFirestore.instance.collection('users').doc(uid)
    //   .update({'isAvailable': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromARGB(255, 255, 195, 66),
              Color.fromARGB(255, 255, 240, 153),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Fixed header.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: widget.profileImagePath.isEmpty
                            ? Image.asset(
                                'assets/images/profile.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                widget.profileImagePath,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                      'assets/images/profile.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Hi ${widget.userName},\n$_greeting',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.notifications_none,
                      size: 26,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildAvailabilityCard(),
                            const SizedBox(height: 16),
                            _buildStatsRow(),
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Requests',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: navigate to full request
                                      // history / Jobs tab.
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'View all',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE30613),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_recentRequests.isEmpty)
                              _buildEmptyRequestsState()
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  children: _recentRequests
                                      .map(_buildRequestTile)
                                      .toList(),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // Bottom navigation bar overlays the scrollable content.
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: _ProviderBottomNavBar(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isOnline
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.shade300,
              ),
              child: Icon(
                _isOnline ? Icons.bolt_rounded : Icons.bolt_outlined,
                color: _isOnline ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? 'You\'re Online' : 'You\'re Offline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isOnline ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOnline
                        ? 'Visible to nearby customers'
                        : 'You won\'t receive new requests',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _isOnline
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isOnline,
              onChanged: _setOnline,
              activeColor: Colors.white,
              activeTrackColor: Colors.grey.shade700,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.checklist_rounded,
              label: 'Jobs Today',
              value: '$_jobsToday',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _StatCard(
              icon: Icons.payments_outlined,
              label: 'Earnings Today',
              value: 'Rs. ${_earningsToday.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No requests yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New job requests will show up here',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(_JobRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: Icon(
              _iconForService(request.serviceLabel),
              size: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.serviceLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.customerName} · ${request.location}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  request.time,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: request.status),
              if (request.status == _JobStatus.completed) ...[
                const SizedBox(height: 6),
                Text(
                  'Rs. ${request.earnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForService(String serviceLabel) {
    switch (serviceLabel) {
      case 'Mechanic':
        return Icons.build_rounded;
      case 'Tow Truck':
        return Icons.local_shipping_rounded;
      case 'Fuel Delivery':
        return Icons.local_gas_station_rounded;
      case 'Flat Tire Change':
        return Icons.tire_repair_rounded;
      case 'Battery Boost':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.build_circle_outlined;
    }
  }
}

enum _JobStatus { completed, cancelled, inProgress }

class _JobRequest {
  final String serviceLabel;
  final String customerName;
  final String location;
  final String time;
  final _JobStatus status;
  final double earnings;

  const _JobRequest({
    required this.serviceLabel,
    required this.customerName,
    required this.location,
    required this.time,
    required this.status,
    required this.earnings,
  });
}

class _StatusBadge extends StatelessWidget {
  final _JobStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _JobStatus.completed => ('Completed', Colors.green.shade600),
      _JobStatus.cancelled => ('Cancelled', Colors.red.shade400),
      _JobStatus.inProgress => ('In Progress', Colors.orange.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ProviderBottomNavBar extends StatelessWidget {
  const _ProviderBottomNavBar();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      height: 86 + bottomInset,
      padding: EdgeInsets.only(top: 10, bottom: bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _NavItem(label: 'Home', icon: Icons.home_rounded, isActive: true),
          _NavItem(label: 'Jobs', icon: Icons.assignment_outlined),
          _NavItem(
            label: 'Earnings',
            icon: Icons.account_balance_wallet_outlined,
          ),
          _NavItem(label: 'More', icon: Icons.apps_rounded),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const _NavItem({
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black : Colors.grey.shade600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
