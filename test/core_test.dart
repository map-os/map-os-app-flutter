import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapos_app/data/models/admin.dart';
import 'package:mapos_app/data/models/cobranca.dart';
import 'package:mapos_app/data/models/gestao.dart';
import 'package:mapos_app/data/models/venda.dart';
import 'package:mapos_app/features/garantias/garantias_pages.dart';
import 'package:mapos_app/features/onboarding/qr_servidor_page.dart';
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
    test('adiciona https e remove o prefixo da API e barras', () {
      expect(AppConfig.normalizeBaseUrl(' demo.mapos.com.br/api/v1/ '), 'https://demo.mapos.com.br');
      expect(AppConfig.normalizeBaseUrl('demo.mapos.com.br/api/v2'), 'https://demo.mapos.com.br');
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
      expect(Fmt.apiDate(DateTime(2026, 1, 5)), '2026-01-05');
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
    final json = {
      'id': 9,
      'status': 'Em Andamento',
      'cliente': {'id': 1, 'nome': 'Coca Cola Femsa Brasil Ltda', 'celular': '(00) 00000-0000', 'telefone': null, 'email': null, 'documento': null},
      'tecnico': {'id': 1, 'nome': 'Demo Mapos'},
      'data_inicial': '2026-08-24',
      'data_final': '2026-08-28',
      'garantia_dias': 90,
      'termo_garantia': {'id': 2, 'referencia': '90 dias'},
      'descricao_produto': 'iPhone\nTela',
      'faturado': false,
      'editavel': true,
      'totais': {
        'produtos': '1773.20',
        'servicos': '1364.00',
        'bruto': '3137.20',
        'desconto': '10.00',
        'total': '3127.20',
        'desconto_geral': {'tipo': 'real', 'valor': '10.00'},
        'desconto_itens': '46.80',
      },
      'produtos': [
        {'id': 8, 'produto_id': 3, 'descricao': 'vidro temperado', 'unidade': 'UN', 'quantidade': 7, 'preco': '260.00', 'desconto': {'tipo': 'real', 'valor': '46.80'}, 'subtotal': '1773.20'},
      ],
      'servicos': [
        {'id': 8, 'servico_id': 3, 'nome': 'instalação', 'quantidade': 6.82, 'preco': '200.00', 'desconto': null, 'subtotal': '1364.00'},
      ],
      'anexos': [
        {'id': 10, 'nome': 'a.png', 'imagem': true, 'url': 'https://x/api/v2/os/9/anexos/10', 'miniatura_url': 'https://x/api/v2/os/9/anexos/10?miniatura=true'},
      ],
      'anotacoes': [
        {'id': 3, 'texto': '[Demo Mapos] nota teste', 'data_hora': '2026-11-22T18:18:22-03:00'},
      ],
      'historico': [
        {'status_anterior': 'Aberto', 'status_novo': 'Em Andamento', 'autor': {'id': 1, 'nome': 'Demo Mapos'}, 'data_hora': '2026-11-22T18:00:00-03:00'},
      ],
    };

    test('lê os totais calculados pelo servidor', () {
      final os = OrdemServico.fromJson(json);
      expect(os.id, 9);
      expect(os.nomeCliente, 'Coca Cola Femsa Brasil Ltda');
      expect(os.responsavel, 'Demo Mapos');
      expect(os.produtos.single.itemId, 8);
      expect(os.produtos.single.desconto?.valor, 46.80);
      expect(os.servicos.single.quantidade, 6.82);
      expect(os.subtotal, closeTo(3137.20, 0.001));
      expect(os.temDesconto, isTrue);
      expect(os.total, closeTo(3127.20, 0.001));
      expect(os.valorDoDesconto, closeTo(10, 0.001));
      expect(os.garantia, '90');
      expect(os.termoGarantiaId, 2);
      expect(os.anexos.single.isImage, isTrue);
      expect(os.anexos.single.thumbUrl, endsWith('miniatura=true'));
      expect(os.anotacoes.single.dataHora, DateTime.parse('2026-11-22T18:18:22-03:00').toLocal());
      expect(os.historico.single.autor, 'Demo Mapos');
    });

    test('OsInput envia datas ISO e os campos da v2', () {
      final body = OsInput(
        clienteId: 1,
        usuarioId: 2,
        status: 'Aberto',
        dataInicial: DateTime(2026, 11, 22),
        dataFinal: DateTime(2026, 11, 25),
        garantia: '30',
      ).toJson();
      expect(body['data_inicial'], '2026-11-22');
      expect(body['data_final'], '2026-11-25');
      expect(body['cliente_id'], 1);
      expect(body['tecnico_id'], 2);
      expect(body['garantia_dias'], 30);
    });
  });

  group('ApiClient', () {
    late SessionStore session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'baseURL': 'https://demo.test'});
      FlutterSecureStorage.setMockInitialValues({'v2_access_token': 'old', 'v2_refresh_token': 'r1'});
      session = await SessionStore.create();
    });

    http.Response ok(Object data, {Map<String, dynamic>? meta}) =>
        http.Response(jsonEncode({'data': data, if (meta != null) 'meta': meta}), 200, headers: {'content-type': 'application/json; charset=utf-8'});

    http.Response problema(int status, String codigo, {Map<String, String> erros = const {}}) => http.Response(
          jsonEncode({'type': 'urn:mapos:erro:$codigo', 'title': 'Erro', 'status': status, 'codigo': codigo, 'detail': 'Detalhe $codigo', if (erros.isNotEmpty) 'erros': erros}),
          status,
          headers: {'content-type': 'application/problem+json; charset=utf-8'},
        );

    test('renova o token em 401 e repete a requisição', () async {
      final seen = <String>[];
      final client = MockClient((req) async {
        seen.add('${req.method} ${req.url.path} ${req.headers['Authorization'] ?? ''}');
        if (req.url.path.endsWith('/auth/renovar')) {
          expect(jsonDecode(req.body)['refresh_token'], 'r1');
          return ok({'access_token': 'new', 'refresh_token': 'r2', 'sessao': 's1'});
        }
        if (req.headers['Authorization'] == 'Bearer old') return problema(401, 'token_expirado');
        return ok([1, 2, 3]);
      });

      final api = ApiClient(session, client: client);
      expect(await api.get('/clientes'), [1, 2, 3]);
      expect(session.accessToken, 'new');
      expect(session.refreshToken, 'r2');
      expect(seen, [
        'GET /api/v2/clientes Bearer old',
        'POST /api/v2/auth/renovar ',
        'GET /api/v2/clientes Bearer new',
      ]);
    });

    test('403 é falta de permissão: não renova nem encerra a sessão', () async {
      var renovou = false;
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/auth/renovar')) renovou = true;
        return problema(403, 'sem_permissao');
      });
      final api = ApiClient(session, client: client);

      await expectLater(api.get('/usuarios'), throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', 'sem_permissao')));
      expect(renovou, isFalse);
      expect(session.hasSession, isTrue);
    });

    test('encerra a sessão quando o refresh falha', () async {
      var expired = false;
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/auth/renovar')) return problema(401, 'refresh_reutilizado');
        return problema(401, 'token_expirado');
      });
      final api = ApiClient(session, client: client)..onSessionExpired = () => expired = true;

      await expectLater(api.get('/os'), throwsA(isA<ApiException>()));
      expect(expired, isTrue);
      expect(session.hasSession, isFalse);
    });

    test('erros de validação trazem a mensagem de cada campo', () async {
      final api = ApiClient(session, client: MockClient((_) async => problema(422, 'validacao', erros: {'endereco.cep': 'CEP inválido.'})));

      await expectLater(
        api.post('/clientes', body: {}),
        throwsA(isA<ApiException>()
            .having((e) => e.isValidation, 'isValidation', isTrue)
            .having((e) => e.erroDo('cep'), 'erroDo', 'CEP inválido.')),
      );
    });

    test('listagem traz a paginação do meta', () async {
      final api = ApiClient(session, client: MockClient((req) async {
        expect(req.url.queryParameters['pagina'], '2');
        return ok([{'id': 1}], meta: {'pagina': 2, 'por_pagina': 20, 'total': 21, 'paginas': 2});
      }));

      final pagina = await api.getPage('/os', query: {'pagina': 2});
      expect(pagina.items.single['id'], 1);
      expect(pagina.total, 21);
      expect(pagina.temMais, isFalse);
    });

    test('204 não tem corpo', () async {
      final api = ApiClient(session, client: MockClient((_) async => http.Response('', 204)));
      expect(await api.delete('/os/1'), isNull);
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
      expect(await api.get('/produtos', cache: true), [
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

  group('SessionStore', () {
    test('apaga os tokens da v1 deixados por versões antigas do app', () async {
      SharedPreferences.setMockInitialValues({'baseURL': 'https://demo.test', 'access_token': 'v1', 'refresh_token': 'v1r', 'permissions': '{}'});
      FlutterSecureStorage.setMockInitialValues({});
      final session = await SessionStore.create();
      final prefs = await SharedPreferences.getInstance();

      expect(session.hasSession, isFalse);
      expect(prefs.containsKey('access_token'), isFalse);
      expect(session.baseUrl, 'https://demo.test');
    });
  });

  test('endereço lido do QR code do servidor', () {
    expect(enderecoDoQr('https://loja.com.br/mapos/api/v2'), 'https://loja.com.br/mapos');
    expect(enderecoDoQr('http://192.168.0.10/mapos/'), 'http://192.168.0.10/mapos');
    expect(enderecoDoQr('texto qualquer'), isNull);
    expect(enderecoDoQr('ftp://x.com'), isNull);
  });

  test('termo de garantia em texto vira HTML escapado', () {
    expect(textoParaHtml('Linha 1\nLinha <2>\n\nOutro parágrafo'), '<p>Linha 1<br>Linha &lt;2&gt;</p><p>Outro parágrafo</p>');
    expect(textoParaHtml('   '), '');
  });

  test('venda, lançamento, cobrança e arquivo da v2', () {
    final v = Venda.fromJson({
      'id': 7,
      'status': 'Aberto',
      'cliente': {'id': 3, 'nome': 'Ana'},
      'vendedor': null,
      'faturado': false,
      'editavel': true,
      'totais': {'produtos': '20.00', 'desconto': '2.00', 'total': '18.00', 'desconto_geral': {'tipo': 'porcento', 'valor': '10.00'}},
      'produtos': [],
    });
    expect((v.nomeCliente, v.total, v.valorDoDesconto, v.tipoDesconto), ('Ana', 18.0, 2.0, 'porcento'));
    expect(Venda.fromJson({'id': 1, 'status': 'Aberto', 'cliente': {'id': 1, 'nome': 'B'}, 'total': '5.50'}).total, 5.5);

    final l = Lancamento.fromJson({'id': 1, 'tipo': 'despesa', 'descricao': 'Luz', 'valor': '120.00', 'valor_liquido': '110.00', 'pago': false, 'situacao': 'vencido', 'data_vencimento': '2026-11-01'});
    expect((l.receita, l.valorLiquido, l.situacao, l.vencimento?.day), (false, 110.0, 'vencido', 1));

    final c = Cobranca.fromJson({'id': 2, 'status': 'paid', 'situacao': 'Paga', 'valor': '50.00', 'origem': {'tipo': 'venda', 'id': 9}, 'link_boleto': 'https://x/b'});
    expect((c.origem, c.paga, c.link), ('Venda #9', true, 'https://x/b'));

    final a = Arquivo.fromJson({'id': 1, 'nome': 'contrato', 'url': '/x', 'extensao': '.pdf', 'tamanho_kb': 2048});
    expect((a.nomeDoArquivo, a.tamanho, a.imagem), ('contrato.pdf', '2 MB', false));
  });

  test('configurações, grupos e e-mails da administração', () {
    final aba = AbaDeConfiguracao.fromJson({
      'id': 'email',
      'nome': 'E-mail',
      'campos': [
        {'chave': 'EMAIL_SMTP_PASS', 'rotulo': 'Senha', 'tipo': 'segredo', 'grupo': null, 'ajuda': null, 'opcoes': null, 'valor': {'definido': true}},
        {'chave': 'EMAIL_PROTOCOL', 'rotulo': 'Protocolo', 'tipo': 'opcao', 'grupo': 'SMTP', 'ajuda': null, 'opcoes': [{'valor': 'smtp', 'nome': 'SMTP'}], 'valor': 'smtp'},
      ],
    });
    expect(aba.campos.first.segredoDefinido, isTrue);
    expect(aba.campos.last.opcoes.single, ('smtp', 'SMTP'));
    final g = GrupoDePermissao.fromJson({'id': 2, 'nome': 'Técnicos', 'ativo': true, 'exigir_2fa': true, 'permissoes': ['vOs', 'aOs'], 'usuarios': 3});
    expect((g.exigir2fa, g.permissoes.length, g.usuarios), (true, 2, 3));
    expect(EmailNaFila.fromJson({'id': 1, 'para': 'a@b.com', 'status': 'failed'}).situacao, 'Falhou');
  });
}
