import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sobre Nós'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 50,
                backgroundImage: AssetImage('lib/assets/images/logo-two.png'), // Substitua 'lib/assets/images/logo-two.png' pelo caminho do seu logotipo
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Projeto MAP-OS',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            SizedBox(height: 10.0),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Projeto voltado a fazer controle de ordens de serviços para assistências técnicas em geral.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            // Text(
            //   'Como nos encontrar?',
            //   style: TextStyle(
            //     fontSize: 18.0,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Adicione ação para abrir o link do Github
                  },
                  child: Image.asset(
                    'lib/assets/images/github.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Adicione ação para abrir o link do Telegram
                  },
                  child: Image.asset(
                    'lib/assets/images/telegram.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Adicione ação para abrir o link do Whatsapp
                  },
                  child: Image.asset(
                    'lib/assets/images/whatsapp.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
