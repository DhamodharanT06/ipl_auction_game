import 'package:flutter/material.dart';
import 'dart:math';
import 'package:ipl_auction_game/homepage.dart';
import 'package:ipl_auction_game/parameters.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // editable user fields
  String _name = 'Player Name';
  String _email = 'User Email';
  String _phone = 'User Phone';
  String _dob = 'User DOB';
  var count = {
    "Total Played": 0,
    "1st Place": 0, 
    "2nd Place": 0,
    "3rd Place": 0,
  };

  Widget stats(String title, {double? width}) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: iconGold, width: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: iconGold)),
            SizedBox(height: 6.0),
            Divider(color: iconGold, thickness: 0.5),
            Text(count[title].toString(), textAlign: TextAlign.center, style: TextStyle(color: iconGold, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog({required String title, required String initialValue, required ValueChanged<String> onSave, TextInputType keyboardType = TextInputType.text}) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: title),
        ),
        backgroundColor: Colors.purple.shade100,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text('Save')),
        ],
      ),
    );

    if (result != null) {
      onSave(result);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _dob = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year.toString().padLeft(4, '0')}";
      });
    }
  }

  Widget details(String label, String value, IconData iconData) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Icon(iconData, color: iconGold),
            trailing: IconButton(
              onPressed: () async {
                if (label == 'Date of Birth') {
                  await _pickDate();
                }else if (label == 'E-Mail') {
                  await _showEditDialog(
                    title: 'E-Mail',
                    initialValue: _email,
                    keyboardType: TextInputType.emailAddress,
                    onSave: (v) => setState(() => _email = v.isEmpty ? _email : v),
                  );
                } else if (label == 'Username') {
                  await _showEditDialog(
                    title: 'Username',
                    initialValue: _name,
                    keyboardType: TextInputType.text,
                    onSave: (v) => setState(() => _name = v.isEmpty ? _name : v),
                  );
                } else if (label == 'Phone') {
                  await _showEditDialog(
                    title: 'Phone',
                    initialValue: _phone,
                    keyboardType: TextInputType.phone,
                    onSave: (v) => setState(() => _phone = v.isEmpty ? _phone : v),
                  );
                }
              },
              icon: Icon(Icons.edit, color: iconGold),
            ),
            title: Text(label, style: TextStyle(color: iconGold)),
            subtitle: Text(label == 'E-Mail' ? _email : label == 'Phone' ? _phone : label == 'Username' ? _name : _dob, style: TextStyle(color: iconGold)),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final double avatarOuter = min(w * 0.14, 60);
    final double avatarInner = max(avatarOuter - 2.0, 24.0);
    final EdgeInsets contentPad = EdgeInsets.symmetric(horizontal: max(12.0, w * 0.05), vertical: 12.0);
    final double cardWidth = min(w * 0.96, 900);
    final double logoutWidth = min(w * 0.6, 220);

    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        title: Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w700, color: iconGold),
        ),
        leading: Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: avatarOuter,
            height: avatarOuter,
            child: Image.asset('assets/Logo_no_bg.png', fit: BoxFit.contain),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => Homepage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: (_, __, ___, child) => child,
                ),
                (route) => false,
              );
            },
            icon: Icon(Icons.home, color: iconGold),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: contentPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: h * 0.03),
              Container(
                width: cardWidth,
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                decoration: BoxDecoration(
                  gradient: iconGradient.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: iconGold, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: iconGold,
                      radius: avatarOuter,
                      child: CircleAvatar(
                        radius: avatarInner,
                        backgroundColor: iconPurple.withAlpha(100),
                        backgroundImage: AssetImage('assets/Logo_no_bg.png'),
                      ),
                    ),
                    SizedBox(width: max(12.0, w * 0.04)),
                    Expanded(
                      child: Text(
                        _name,
                        style: TextStyle(fontSize: max(16.0, w * 0.05), color: iconGold),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.02),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(top: 4, bottom: 4),
                child: Column(
                  children: [
                    details("Username", _name , Icons.person),
                    details("E-Mail", _email, Icons.email),
                    details("Phone", _phone, Icons.phone),
                    details("Date of Birth", _dob, Icons.cake),
                    SizedBox(height: h * 0.01),
                    Divider(color: iconGold, thickness: 0.5),
                    SizedBox(height: h * 0.02),
                    Text("Stats", style: TextStyle(fontSize: max(18.0, w * 0.05), fontWeight: FontWeight.w700, color: iconGold)),
                    SizedBox(height: h * 0.01),
                    Container(
                      width: cardWidth,
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final double avail = constraints.maxWidth;
                        // target 4 items on wide screens, wrap as needed
                        final double childWidth = min(160, max(110, avail * 0.22));
                        return Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          alignment: WrapAlignment.center,
                          children: [
                            stats("Total Played", width: childWidth),
                            stats("1st Place", width: childWidth),
                            stats("2nd Place", width: childWidth),
                            stats("3rd Place", width: childWidth),
                          ],
                        );
                      }),
                    ),
                    SizedBox(height: h * 0.04),
                    InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => Homepage(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            transitionsBuilder: (_, __, ___, child) => child,
                          ),
                          (route) => false,
                        );
                      },
                      splashColor: iconPurple,
                      child: Container(
                        height: max(44.0, h * 0.06),
                        width: logoutWidth,
                        decoration: BoxDecoration(
                          color: iconPurple.withAlpha(125),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "Logout",
                            style: TextStyle(
                              color: iconGold,
                              fontSize: max(14.0, w * 0.04),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
