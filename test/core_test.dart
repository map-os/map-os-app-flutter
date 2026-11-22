import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapos_app/core/config/app_config.dart';
import 'package:mapos_app/core/network/api_client.dart';
import 'package:mapos_app/core/network/api_exception.dart';
import 'package:mapos_app/core/storage/session_store.dart';
import 'package:mapos_app/core/utils/formatters.dart';
import 'package:mapos_app/core/utils/input_masks.dart';
import 'package:mapos_app/data/models/ordem_servico.dart';
import 'package:shared_preferences/shared_preferences.dart';

TextEditingValue _type(TextInputFormatter f, String text) =>
    f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('AppConfig.normalizeBaseUrl', () {
    test('adiciona https e remove /api/v1 e barras', () {
      expect(AppConfig.normalizeBaseUrl(' demo.mapos.com.br/api/v1/ '), 'https://demo.mapos.com.br');
      expect(AppConfig.normalizeBaseUrl('http://10.0.0.2/mapos/'), 'http://10.0.0.2/mapos');
    });
  });

  group('Fmt', () {
    test('moeda e parse', () {
      expect(Fmt.money(1234.5).replaceAll(' ', ' '), r'R$ 1.234,50');
      expect(Fmt.parseMoney(r'R$ 1.234,56'), 1234.56);
    });

    test('remove HTML e neutraliza conteúdo malicioso', () {
      const html = '<p dir="auto">">&lt;svg onload="alert&#40;1&#41;"&gt;</p><p>linha 2</p>';
      final text = Fmt.plain(html);
      expect(text.contains('<p'), isFalse);
      expect(text, contains('linha 2'));
    });

    test('datas inválidas da API viram null', () {
      expect(asDate('0000-00-00'), isNull);
      expect(asDate('2026-08-24'), DateTime(2026, 8, 24));
      expect(Fmt.apiDate(DateTime(2026, 1, 5)), '05/01/2026');
    });

    test('iniciais', () {
      expect(Fmt.initials('Coca Cola Femsa Brasil'), 'CB');
      expect(Fmt.initials(''), '?');
    });
  });

  group('Máscaras', () {
    test('telefone fixo e celular', () {
      expect(_type(PatternMask.phone(), '1154126032').text, '(11) 5412-6032');
      expect(_type(PatternMask.phone(), '11987654321').text, '(11) 98765-4321');
    });

    test('CPF e CNPJ', () {
      expect(_type(PatternMask.cpfCnpj(), '60002152087').text, '600.021.520-87');
      expect(_type(PatternMask.cpfCnpj(), '10809493000169').text, '10.809.493/0001-69');
    });

    test('dinheiro digitando da direita', () {
      expect(_type(MoneyMask(), '12345').text.replaceAll(' ', ' '), r'R$ 123,45');
    });
  });

  group('OrdemServico.fromJson', () {
    // Amostra real de GET /os/{id} da API demo.
    final json = {
      'idOs': '9',
      'dataInicial': '2026-08-24',
      'dataFinal': '2026-08-28',
      'status': 'Em Andamento',
      'desconto': '10.00',
      'valor_desconto': '3127.20',
      'tipo_desconto': 'real',
      'clientes_id': '1',
      'usuarios_id': '1',
      'nomeCliente': 'Coca Cola Femsa Brasil Ltda',
      'celular_cliente': '(00) 00000-0000',
      'nome': 'Demo Mapos',
      'produtos': [
        {'idProdutos_os': '8', 'quantidade': '7', 'descricao': 'vidro temperado', 'preco': '260.00', 'produtos_id': '3', 'subTotal': '1773.20'},
      ],
      'servicos': [
        {'idServicos_os': '8', 'quantidade': '6.82', 'preco': '200.00', 'servicos_id': '3', 'subTotal': '1364.00', 'nome': 'instalação'},
      ],
      'anexos': [
        {'idAnexos': '10', 'anexo': 'a.png', 'url': 'https://x/api/v1/os/7/anexos/10', 'thumb_url': 'https://x/api/v1/os/7/anexos/10?miniatura=1'},
      ],
      'anotacoes': [
        {'idAnotacoes': '3', 'anotacao': '[Demo Mapos] nota teste', 'data_hora': '2026-11-22 18:18:22'},
      ],
    };

    test('calcula totais a partir dos itens', () {
      final os = OrdemServico.fromJson(json);
      expect(os.id, 9);
      expect(os.produtos.single.itemId, 8);
      expect(os.servicos.single.quantidade, 6.82);
      expect(os.subtotal, closeTo(3137.20, 0.001));
      expect(os.temDesconto, isTrue);
      expect(os.total, closeTo(3127.20, 0.001));
      expect(os.valorDoDesconto, closeTo(10, 0.001));
      expect(os.anexos.single.isImage, isTrue);
      expect(os.anotacoes.single.dataHora, DateTime(2026, 11, 22, 18, 18, 22));
    });

    test('OsInput envia datas em dd/MM/yyyy', () {
      final body = OsInput(
        clienteId: 1,
        usuarioId: 1,
        status: 'Aberto',
        dataInicial: DateTime(2026, 11, 22),
        dataFinal: DateTime(2026, 11, 25),
      ).toJson();
      expect(body['dataInicial'], '22/11/2026');
      expect(body['dataFinal'], '25/11/2026');
    });
  });

  group('ApiClient', () {
    late SessionStore session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'baseURL': 'https://demo.test',
        'access_token': 'old',
        'refresh_token': 'r1',
      });
      session = await SessionStore.create();
    });

    http.Response ok(Object result) =>
        http.Response(jsonEncode({'status': true, 'message': 'ok', 'result': result}), 200);

    test('renova o token em 403 e repete a requisição', () async {
      final seen = <String>[];
      final client = MockClient((req) async {
        seen.add('${req.method} ${req.url.path} ${req.headers['Authorization'] ?? ''}');
        if (req.url.path.endsWith('/refresh')) {
          expect(jsonDecode(req.body)['refresh_token'], 'r1');
          return ok({'access_token': 'new', 'refresh_token': 'r2'});
        }
        if (req.headers['Authorization'] == 'Bearer old') {
          return http.Response(jsonEncode({'status': false, 'message': 'Faça o login novamente!'}), 403);
        }
        return ok([1, 2, 3]);
      });

      final api = ApiClient(session, client: client);
      final result = await api.get('/clientes');

      expect(result, [1, 2, 3]);
      expect(session.accessToken, 'new');
      expect(session.refreshToken, 'r2');
      expect(seen, [
        'GET /api/v1/clientes Bearer old',
        'POST /api/v1/refresh ',
        'GET /api/v1/clientes Bearer new',
      ]);
    });

    test('encerra a sessão quando o refresh falha', () async {
      var expired = false;
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/refresh')) return http.Response('{"status":false}', 401);
        return http.Response('{"status":false,"message":"x"}', 403);
      });
      final api = ApiClient(session, client: client)..onSessionExpired = () => expired = true;

      await expectLater(api.get('/os'), throwsA(isA<ApiException>()));
      expect(expired, isTrue);
      expect(session.hasSession, isFalse);
    });

    test('usa o cache quando está offline', () async {
      var online = true;
      final client = MockClient((req) async {
        if (!online) throw http.ClientException('offline');
        return ok([
          {'id': 1},
        ]);
      });
      final api = ApiClient(session, client: client);

      await api.get('/produtos', cache: true);
      online = false;
      final cached = await api.get('/produtos', cache: true);
      expect(cached, [
        {'id': 1},
      ]);
      await expectLater(api.get('/servicos', cache: true), throwsA(isA<ApiException>()));
    });

    test('resposta HTML vira erro amigável', () async {
      final api = ApiClient(session, client: MockClient((_) async => http.Response('<html></html>', 404)));
      await expectLater(
        api.get('/x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('não encontrado'))),
      );
    });
  });
}
