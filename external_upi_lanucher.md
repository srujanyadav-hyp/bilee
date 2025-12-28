dependencies:
  flutter:
    sdk: flutter
  external_app_launcher: ^4.0.3  # యాప్ ని డైరెక్ట్ గా ఓపెన్ చేయడానికి


  <queries>
    <package android:name="com.google.android.apps.nbu.paisa.user" /> <package android:name="com.phonepe.app" />                      
       <package android:name="net.one97.paytm" />                   
             <package android:name="in.org.npci.upiapp" />   
     </queries>


     import 'package:flutter/material.dart';
import 'package:external_app_launcher/external_app_launcher.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UpiLauncherScreen(),
  ));
}

class UpiLauncherScreen extends StatelessWidget {
  
  // యాప్స్ లిస్ట్ (Packages)
  final List<Map<String, String>> upiApps = [
    {
      'name': 'Google Pay',
      'package': 'com.google.android.apps.nbu.paisa.user',
      'scheme': 'gpay://'
    },
    {
      'name': 'PhonePe',
      'package': 'com.phonepe.app',
      'scheme': 'phonepe://'
    },
    {
      'name': 'Paytm',
      'package': 'net.one97.paytm',
      'scheme': 'paytmmp://'
    },
    {
      'name': 'BHIM',
      'package': 'in.org.npci.upiapp',
      'scheme': 'bhim://'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select UPI App")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Open App & Scan Manually", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 10),
            Text("Select an app to open its Home Screen:"),
            SizedBox(height: 20),

            // లిస్ట్ ని చూపిస్తున్నాం
            Expanded(
              child: ListView.builder(
                itemCount: upiApps.length,
                itemBuilder: (context, index) {
                  final app = upiApps[index];
                  
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.touch_app, color: Colors.blue),
                      title: Text(app['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        // లాజిక్: యాప్ ని ఓపెన్ చెయ్యి (No Data Passing)
                        await LaunchApp.openApp(
                          androidPackageName: app['package']!,
                          iosUrlScheme: app['scheme']!,
                          openStore: false, // యాప్ లేకపోతే ప్లే స్టోర్ కి వెళ్లొద్దు (Optional)
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}