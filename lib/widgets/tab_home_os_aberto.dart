import 'package:flutter/material.dart';

class MeuWidgetPersonalizado extends StatelessWidget {
  final String titulo;
  final String texto;

  MeuWidgetPersonalizado({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0, // Reduzindo o tamanho da fonte para 16.0
            ),
          ),
          SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            height: 200.0,
            child: ListView(
              children: [
                ListTile(
                  title: Text('Item 1', style: TextStyle(fontSize: 14.0)), // Reduzindo o tamanho da fonte para 14.0
                  subtitle: Text('Descrição do item 1', style: TextStyle(fontSize: 12.0)), // Reduzindo o tamanho da fonte para 12.0
                  leading: Icon(Icons.star),
                ),
                ListTile(
                  title: Text('Item 2', style: TextStyle(fontSize: 14.0)),
                  subtitle: Text('Descrição do item 2', style: TextStyle(fontSize: 12.0)),
                  leading: Icon(Icons.star),
                ),
                ListTile(
                  title: Text('Item 3', style: TextStyle(fontSize: 14.0)),
                  subtitle: Text('Descrição do item 3', style: TextStyle(fontSize: 12.0)),
                  leading: Icon(Icons.star),
                ),
                ListTile(
                  title: Text('Item 4', style: TextStyle(fontSize: 14.0)),
                  subtitle: Text('Descrição do item 4', style: TextStyle(fontSize: 12.0)),
                  leading: Icon(Icons.star),
                ),
                ListTile(
                  title: Text('Item 5', style: TextStyle(fontSize: 14.0)),
                  subtitle: Text('Descrição do item 5', style: TextStyle(fontSize: 12.0)),
                  leading: Icon(Icons.star),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}