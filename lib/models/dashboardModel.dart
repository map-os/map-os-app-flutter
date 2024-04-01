import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';

class OSAberta {
  final String id;
  final String nomeCliente;
  final String dataInicial;
  final String dataFinal;

  OSAberta({required this.id, required this.nomeCliente, required this.dataInicial, required this.dataFinal});
}

class OSAndamento {
  final String id;
  final String nomeCliente;
  final String dataInicial;
  final String dataFinal;

  OSAndamento({required this.id, required this.nomeCliente, required this.dataInicial, required this.dataFinal});
}

class EstoqueBaixo {
  final String id;
  final String descricao;
  final String precoVenda;
  final String estoque;

  EstoqueBaixo({required this.id, required this.descricao, required this.precoVenda, required this.estoque});
}

class DashboardData {
  int countOs = 0;
  int clientes = 0;
  int produtos = 0;
  int servicos = 0;
  int garantias = 0;
  int vendas = 0;
  List<OSAberta> osAbertasList = [];
  List<OSAndamento> osAndamentoList = [];
  List<EstoqueBaixo> estoqueBaixoList = [];

  Future<void> fetchData(BuildContext context) async {
    if (APIConfig.baseURL == null) {
      await APIConfig.initBaseURL();
      if (APIConfig.baseURL == null) {
        return;
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };

    var url = '${APIConfig.baseURL}${APIConfig.indexEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        countOs = data['result']['countOs'] ?? 0;
        clientes = data['result']['clientes'] ?? 0;
        produtos = data['result']['produtos'] ?? 0;
        servicos = data['result']['servicos'] ?? 0;
        garantias = data['result']['garantias'] ?? 0;
        vendas = data['result']['vendas'] ?? 0;
        osAbertasList = data['result']['osAbertas']
            .map<OSAberta>((os) => OSAberta(
          id: os['idOs'].toString(),
          nomeCliente: os['nomeCliente'].toString(),
          dataInicial: os['dataInicial'].toString(),
          dataFinal: os['dataFinal'].toString(),
        ))
            .toList();
        osAndamentoList = data['result']['osAndamento']
            .map<OSAndamento>((os) => OSAndamento(
          id: os['idOs'].toString(),
          nomeCliente: os['nomeCliente'].toString(),
          dataInicial: os['dataInicial'].toString(),
          dataFinal: os['dataFinal'].toString(),
        ))
            .toList();
        estoqueBaixoList = data['result']['estoqueBaixo']
            .map<EstoqueBaixo>((os) => EstoqueBaixo(
          id: os['idProdutos'].toString(),
          descricao: os['descricao'].toString(),
          precoVenda: os['precoVenda'].toString(),
          estoque: os['estoque'].toString(),
        ))
            .toList();
      } else {
        print(data['message']);
      }
    } else {
      print('ERRO');
    }
  }
}
