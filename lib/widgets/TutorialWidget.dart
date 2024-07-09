import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:mapos_app/pages/login/login_page.dart';

class TutorialScreen extends StatefulWidget {
  @override
  _TutorialScreenState createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  List<Slide> slides = [];

  @override
  void initState() {
    super.initState();
    slides.add(
      Slide(
        title: "Bem-vindo",
        description: "Esse é o APP do MAP-OS, sistema de gerenciamento de ordens de serviços",
        pathImage: "assets/images/logo.png",
        backgroundColor: Color(0xfff3a489),
      ),
    );
    slides.add(
      Slide(
        title: "Primeiro Passo",
        description: "Abra seu MAP-OS WEB vá em configurações>sistema>api, verifique se sua API está ativa \n Caso não esteja precisará ativar a mesma!",
        pathImage: "assets/images/primeiro.png",
        backgroundColor: Color(0xff5c6bc0),
      ),
    );
    slides.add(
      Slide(
        title: "Segundo Passo",
        description: "Copie sua URL API",
        pathImage: "assets/images/segundo.png",
        backgroundColor: Color(0xff009688),
      ),
    );
    slides.add(
      Slide(
        title: "Terceiro Passo",
        description: "Clique no icone de configuração na tela de login do do APP",
        pathImage: "assets/images/terceiro.png",
        backgroundColor: Color(0xffe3f169),
      ),
    );
    slides.add(
      Slide(
        title: "Quarto Passo",
        description: "Cole a URL da sua api e Salve, após isso basta fazer login no app\n usando as mesmas credenciais que usa no sistema web",
        pathImage: "assets/images/quarto.png",
        backgroundColor: Color(0xff009619),
      ),
    );
  }

  void onDonePress() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  Widget renderNextBtn() {
    return Icon(
      Icons.navigate_next,
      color: Color(0xfff1732f),
      size: 35.0,
    );
  }

  Widget renderDoneBtn() {
    return Icon(
      Icons.done,
      color: Color(0xfff1732f),
    );
  }

  Widget renderSkipBtn() {
    return ElevatedButton(
      onPressed: () {
        onDonePress();
      },
      child: Text(
        "Pular",
        style: TextStyle(color: Color(0xfff1732f)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      slides: this.slides,
      renderNextBtn: this.renderNextBtn(),
      renderDoneBtn: this.renderDoneBtn(),
      renderSkipBtn: this.renderSkipBtn(),
      onDonePress: this.onDonePress,
      colorDot: Color(0xFFCCCCCC),
      colorActiveDot: Color(0xfffb6717),
    );
  }
}
