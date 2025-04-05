import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'misc/colors.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(JiboMonieApp(isLoggedIn: isLoggedIn));
}

class JiboMonieApp extends StatelessWidget {
  final bool isLoggedIn;

  const JiboMonieApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JiboMonie',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: isLoggedIn ? const MainScreen() : const AuthScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/auth': (context) => const AuthScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// New Authentication Screen

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Login
        await AuthService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        // Register
        await AuthService.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const FlutterLogo(size: 100),
                const SizedBox(height: 40),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isLogin
                        ? 'Create new account'
                        : 'I already have an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}

// Enhanced MainScreen with logout functionality
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _balanceVisible = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const HomeScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("JiboMonie"),
          centerTitle: true,
          backgroundColor: isDarkMode ? Colors.black : AppColors.background,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen())),
              child: const ProfileAvatar(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(RemixIcons.logout_box_r_line),
              onPressed: _logout,
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: theme.colorScheme.secondary,
          unselectedItemColor: theme.textTheme.bodySmall?.color,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(RemixIcons.home_line),
              title: const Text("Home"),
            ),
            SalomonBottomBarItem(
              icon: const Icon(RemixIcons.history_line),
              title: const Text("History"),
            ),
            SalomonBottomBarItem(
              icon: const Icon(RemixIcons.settings_line),
              title: const Text("Settings"),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced HomeScreen with interactive quick actions
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const BalanceCard(balance: 5000.0),
          const SizedBox(height: 20),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildRecentTransactions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': RemixIcons.arrow_down_line,
        'label': 'Deposit',
        'onTap': () => _showDepositDialog(context)
      },
      {
        'icon': RemixIcons.exchange_line,
        'label': 'Transfer',
        'onTap': () => _showTransferDialog(context)
      },
      {
        'icon': RemixIcons.phone_line,
        'label': 'Airtime',
        'onTap': () => _showAirtimeDialog(context)
      },
      {
        'icon': RemixIcons.wifi_line,
        'label': 'Data',
        'onTap': () => _showDataDialog(context)
      },
      {
        'icon': RemixIcons.lightbulb_line,
        'label': 'Electricity',
        'onTap': () => _showBillDialog(context, 'Electricity')
      },
      {
        'icon': RemixIcons.water_flash_line,
        'label': 'Water',
        'onTap': () => _showBillDialog(context, 'Water')
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.9,
      children: actions
          .map((action) => _buildActionButton(
                context,
                action['icon'] as IconData,
                action['label'] as String,
                action['onTap'] as VoidCallback,
              ))
          .toList(),
    );
  }

  void _showDepositDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Bank'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deposit request submitted')));
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Recipient Account'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transfer successful')));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAirtimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy Airtime'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              items: ['MTN', 'Airtel', 'Glo', '9mobile']
                  .map((network) =>
                      DropdownMenuItem(value: network, child: Text(network)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Network'),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Airtime purchase successful')));
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _showDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              items: ['MTN', 'Airtel', 'Glo', '9mobile']
                  .map((network) =>
                      DropdownMenuItem(value: network, child: Text(network)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Network'),
              onChanged: (value) {},
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              items: [
                '100MB - N100',
                '350MB - N200',
                '1GB - N500',
                '2GB - N1000'
              ]
                  .map((plan) =>
                      DropdownMenuItem(value: plan, child: Text(plan)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Data Plan'),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data purchase successful')));
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _showBillDialog(BuildContext context, String billType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pay $billType Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration:
                  InputDecoration(labelText: '$billType Account Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$billType bill payment successful')));
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor:
                isDarkMode ? AppColors.primary : AppColors.secondaryContainer,
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final transactions = [
      {
        'type': 'transfer',
        'name': 'John Doe',
        'time': '10:30 AM',
        'amount': -1000.0,
        'date': 'Today'
      },
      {
        'type': 'deposit',
        'name': 'Salary',
        'time': '9:15 AM',
        'amount': 50000.0,
        'date': 'Today'
      },
      {
        'type': 'airtime',
        'name': 'Self',
        'time': 'Yesterday',
        'amount': -500.0,
        'date': 'Yesterday'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Transactions",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCredit = tx['amount'] as double > 0;

            return ListTile(
              onTap: () => _showTransactionDetails(context, tx),
              leading: CircleAvatar(
                backgroundColor: isCredit ? Colors.green[100] : Colors.red[100],
                child: Icon(
                  isCredit
                      ? RemixIcons.arrow_down_line
                      : RemixIcons.arrow_up_line,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(tx['name'] as String),
              subtitle: Text("${tx['date']}, ${tx['time']}"),
              trailing: Text(
                "${isCredit ? '+' : '-'}N${(tx['amount'] as double).abs().toStringAsFixed(2)}",
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showTransactionDetails(
      BuildContext context, Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: transaction['amount'] as double > 0
                    ? Colors.green[100]
                    : Colors.red[100],
                child: Icon(
                  transaction['amount'] as double > 0
                      ? RemixIcons.arrow_down_line
                      : RemixIcons.arrow_up_line,
                  size: 30,
                  color: transaction['amount'] as double > 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "${transaction['amount'] as double > 0 ? 'Received' : 'Sent'} N${(transaction['amount'] as double).abs().toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Type', transaction['type'] as String),
            _buildDetailRow('Name', transaction['name'] as String),
            _buildDetailRow(
                'Date', "${transaction['date']}, ${transaction['time']}"),
            _buildDetailRow('Status', 'Completed'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}

// Enhanced HistoryScreen with filtering and search
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'transfer',
      'name': 'John Doe',
      'amount': -1000.0,
      'date': 'Today',
      'time': '10:30 AM',
      'status': 'successful'
    },
    {
      'type': 'deposit',
      'name': 'Salary',
      'amount': 50000.0,
      'date': 'Today',
      'time': '9:15 AM',
      'status': 'successful'
    },
    {
      'type': 'airtime',
      'name': 'Self',
      'amount': -500.0,
      'date': 'Yesterday',
      'time': '4:45 PM',
      'status': 'successful'
    },
    {
      'type': 'data',
      'name': 'Brother',
      'amount': -1000.0,
      'date': 'Yesterday',
      'time': '2:20 PM',
      'status': 'successful'
    },
    {
      'type': 'electricity',
      'name': 'EKEDC',
      'amount': -5000.0,
      'date': '2 days ago',
      'time': '11:10 AM',
      'status': 'successful'
    },
    {
      'type': 'transfer',
      'name': 'Jane Smith',
      'amount': -2500.0,
      'date': '3 days ago',
      'time': '3:30 PM',
      'status': 'successful'
    },
    {
      'type': 'deposit',
      'name': 'Freelance',
      'amount': 15000.0,
      'date': '1 week ago',
      'time': '8:45 AM',
      'status': 'successful'
    },
  ];

  String _searchQuery = '';
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _transactions.where((tx) {
      final matchesSearch = tx['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          tx['amount'].toString().contains(_searchQuery);
      final matchesFilter = _filterType == 'all' || tx['type'] == _filterType;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        actions: [
          IconButton(
            icon: const Icon(RemixIcons.download_cloud_2_line),
            onPressed: () => _exportHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(RemixIcons.search_line),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Transfers', 'transfer'),
                _buildFilterChip('Deposits', 'deposit'),
                _buildFilterChip('Airtime', 'airtime'),
                _buildFilterChip('Data', 'data'),
                _buildFilterChip('Bills', 'electricity'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final isCredit = tx['amount'] as double > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _showTransactionDetails(tx),
                    leading: CircleAvatar(
                      backgroundColor:
                          isCredit ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        isCredit
                            ? RemixIcons.arrow_down_line
                            : RemixIcons.arrow_up_line,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(tx['name'] as String),
                    subtitle: Text('${tx['date']}, ${tx['time']}'),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? '+' : '-'}N${(tx['amount'] as double).abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tx['type'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _filterType == value,
        onSelected: (selected) => setState(() => _filterType = value),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  Future<void> _exportHistory() async {
    // In a real app, this would export to CSV or PDF
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exporting transaction history...')));
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History exported successfully')));
    }
  }
}

class TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsSheet({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction['amount'] as double > 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: isCredit ? Colors.green[100] : Colors.red[100],
              child: Icon(
                isCredit
                    ? RemixIcons.arrow_down_line
                    : RemixIcons.arrow_up_line,
                size: 30,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "${isCredit ? 'Received' : 'Sent'} N${(transaction['amount'] as double).abs().toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Transaction Type', transaction['type'] as String),
          _buildDetailRow('Recipient/Sender', transaction['name'] as String),
          _buildDetailRow(
              'Date', "${transaction['date']}, ${transaction['time']}"),
          _buildDetailRow('Status', 'Completed'),
          _buildDetailRow(
              'Reference', 'JBM${DateTime.now().millisecondsSinceEpoch}'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}

// Enhanced SettingsScreen with more options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricsEnabled = false;
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Preferences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: _darkModeEnabled,
                  onChanged: (value) =>
                      setState(() => _darkModeEnabled = value),
                ),
                SwitchListTile(
                  title: const Text("Enable Biometrics"),
                  value: _biometricsEnabled,
                  onChanged: (value) =>
                      setState(() => _biometricsEnabled = value),
                ),
                SwitchListTile(
                  title: const Text("Notifications"),
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Account",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(RemixIcons.user_3_line),
                  title: const Text("Profile Information"),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen())),
                ),
                ListTile(
                  leading: const Icon(RemixIcons.lock_line),
                  title: const Text("Change Password"),
                  onTap: () => _showChangePasswordDialog(),
                ),
                ListTile(
                  leading: const Icon(RemixIcons.bank_card_line),
                  title: const Text("Bank Accounts"),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Support",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(RemixIcons.customer_service_line),
                  title: const Text("Contact Support"),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(RemixIcons.question_line),
                  title: const Text("FAQs"),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(RemixIcons.shield_line),
                  title: const Text("Privacy Policy"),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => _showLogoutDialog(),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: oldPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmPasswordController,
              decoration:
                  const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords don't match")));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Password changed successfully")));
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }
}

// New Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Center(
              child: ProfileAvatar(size: 80),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "John Doe",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
              child: Text("john.doe@example.com"),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileItem(
                        RemixIcons.phone_line, "+234 812 345 6789"),
                    const Divider(),
                    _buildProfileItem(
                        RemixIcons.map_pin_line, "Lagos, Nigeria"),
                    const Divider(),
                    _buildProfileItem(
                        RemixIcons.bank_card_line, "•••• •••• •••• 7890"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showEditProfileDialog(context),
                child: const Text("Edit Profile"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 16),
          Text(text),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: "John Doe");
    final emailController = TextEditingController(text: "john.doe@example.com");
    final phoneController = TextEditingController(text: "+2348123456789");
    final addressController = TextEditingController(text: "Lagos, Nigeria");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Profile updated successfully")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final double size;

  const ProfileAvatar({Key? key, this.size = 40}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundImage: const NetworkImage(
        'https://marketplace.canva.com/MABGb6Bv-M4/1/thumbnail_large-1/canva-MABGb6Bv-M4.jpg',
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: CircleAvatar(
          radius: size * 0.15,
          backgroundColor: Colors.green,
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final double balance;

  const BalanceCard({Key? key, required this.balance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final state = context.findAncestorStateOfType<_MainScreenState>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDarkMode ? Colors.grey[900] : AppColors.secondaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Account Balance",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: state?._toggleBalanceVisibility,
                icon: Icon(
                  state?._balanceVisible ?? true
                      ? RemixIcons.eye_line
                      : RemixIcons.eye_close_line,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state?._balanceVisible ?? true
                ? "N${balance.toStringAsFixed(2)}"
                : "••••••",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDepositDialog(context),
                  icon: const Icon(RemixIcons.arrow_down_line, size: 16),
                  label: const Text("Deposit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTransferDialog(context),
                  icon: const Icon(RemixIcons.arrow_up_line, size: 16),
                  label: const Text("Transfer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Bank'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deposit request submitted')));
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Recipient Account'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transfer successful')));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 8,
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      elevation: 8,
    ),
  );
}
