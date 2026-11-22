import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/login/login_page.dart';
import 'package:mapos_app/pages/dashboard/dashboard_page.dart';

class InitialPage extends StatefulWidget {
  @override
  _InitialPageState createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  void _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => DashboardPage()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
