import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staircoins/providers/auth_provider.dart';
import 'package:staircoins/theme/app_theme.dart';
import 'package:staircoins/providers/produto_provider.dart';
import 'package:staircoins/models/produto.dart';
import 'package:staircoins/screens/aluno/aluno_historico_trocas_screen.dart';
import 'package:staircoins/providers/turma_provider.dart';

class AlunoProdutosScreen extends StatefulWidget {
  const AlunoProdutosScreen({super.key});

  @override
  State<AlunoProdutosScreen> createState() => _AlunoProdutosScreenState();
}

class _AlunoProdutosScreenState extends State<AlunoProdutosScreen> {
  bool _isLoading = false;
  List<Produto> _produtosTurmas = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      _isLoading = true;
      _produtosTurmas = []; // Limpar produtos antigos
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final produtoProvider =
          Provider.of<ProdutoProvider>(context, listen: false);
      final turmaProvider = Provider.of<TurmaProvider>(context, listen: false);

      if (authProvider.isAuthenticated && authProvider.user != null) {
        final user = authProvider.user!;

        // Filtrar produtos por turmas, se houver turmas
        if (user.turmas.isNotEmpty) {
          // Recarregar todas as turmas para garantir dados atualizados
          await turmaProvider.buscarTurmasPorIds(user.turmas);

          // Buscar turmas do aluno para obter os IDs dos professores
          final turmas = turmaProvider.getTurmasAluno();
          final professoresIds =
              turmas.map((t) => t.professorId).toSet().toList();

          debugPrint('AlunoProdutosScreen: Turmas do aluno: ${turmas.length}');

          // Log detalhado das turmas
          for (var turma in turmas) {
            debugPrint(
                'AlunoProdutosScreen: Turma: ${turma.id} - ${turma.nome} - Professor: ${turma.professorId}');
          }

          debugPrint(
              'AlunoProdutosScreen: Professores das turmas: $professoresIds');

          // Verificar se temos professores
          if (professoresIds.isEmpty) {
            debugPrint(
                'ALERTA: Nenhum professor encontrado para as turmas do aluno!');
          }

          try {
            // Primeiro recarregar todos os produtos para garantir dados atualizados
            await produtoProvider.carregarProdutos();

            debugPrint(
                'AlunoProdutosScreen: Buscando produtos das turmas do aluno e seus professores');

            final produtosTurma = await produtoProvider.buscarProdutosPorTurmas(
                user.turmas,
                professoresIds: professoresIds);

            debugPrint(
                'AlunoProdutosScreen: Encontrados ${produtosTurma.length} produtos para as turmas do aluno');

            // Log detalhado dos produtos encontrados
            for (var produto in produtosTurma) {
              debugPrint(
                  'AlunoProdutosScreen: Produto: ${produto.nome}, turmaId: ${produto.turmaId}, professorId: ${produto.professorId}');
            }

            _produtosTurmas = produtosTurma;
          } catch (e) {
            debugPrint('AlunoProdutosScreen: Erro ao buscar produtos: $e');
          }
        } else {
          debugPrint('AlunoProdutosScreen: Aluno não está em nenhuma turma');
          _produtosTurmas = [];
        }
      } else {
        debugPrint('AlunoProdutosScreen: Usuário não autenticado');
        _produtosTurmas = [];
      }

      debugPrint(
          'AlunoProdutosScreen: Total de ${_produtosTurmas.length} produtos disponíveis para exibição');
    } catch (e) {
      debugPrint('AlunoProdutosScreen: Erro ao carregar produtos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final produtoProvider = Provider.of<ProdutoProvider>(context);
    final user = authProvider.user;
    final moedas = user?.staircoins ?? 0;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (produtoProvider.erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Erro ao carregar produtos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(produtoProvider.erro!),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregarProdutos,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _produtosTurmas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_giftcard_outlined,
                        size: 64, color: AppTheme.mutedForegroundColor),
                    const SizedBox(height: 16),
                    const Text('Nenhum produto disponível',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Aguarde, em breve novos produtos!',
                        style: TextStyle(color: AppTheme.mutedForegroundColor)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _carregarProdutos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Catálogo de Produtos',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${user?.staircoins ?? 0} StairCoins',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: _produtosTurmas.length,
                        itemBuilder: (context, index) {
                          final produto = _produtosTurmas[index];
                          return _buildProdutoCard(
                              context, produto, moedas, user?.id);
                        },
                      ),
                    ),
                  ],
                ),
              ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            heroTag: 'historicoTrocas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlunoHistoricoTrocasScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('Minhas Trocas'),
          ),
        ),
      ],
    );
  }

  Widget _buildProdutoCard(
      BuildContext context, Produto produto, int moedas, String? alunoId) {
    final esgotado = produto.quantidade == 0;
    final temSaldo = moedas >= produto.preco;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do produto
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              width: double.infinity,
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: produto.imagem != null && produto.imagem!.isNotEmpty
                  ? Image.asset(
                      produto.imagem!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.card_giftcard,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
            ),
          ),

          // Informações do produto
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nome e descrição
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nome,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        produto.descricao,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Preço e botão
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: AppTheme.primaryColor, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                '${produto.preco}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          esgotado
                              ? const Text('Esgotado',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))
                              : Text(
                                  temSaldo ? 'Disponível' : 'Insuficiente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: temSaldo
                                        ? AppTheme.successColor
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ElevatedButton(
                          onPressed: (esgotado || !temSaldo)
                              ? null
                              : () {
                                  _showComprarDialog(
                                      context, produto, moedas, alunoId);
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            textStyle: const TextStyle(fontSize: 13),
                            minimumSize: const Size.fromHeight(32),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              esgotado
                                  ? 'Esgotado'
                                  : temSaldo
                                      ? 'Comprar'
                                      : 'Moedas insuficientes',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComprarDialog(BuildContext context, Produto produto, int moedas,
      String? alunoId) async {
    final scaffoldContext = context;
    final saldoSuficiente = moedas >= produto.preco;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Comprar ${produto.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preço: ${produto.preco} StairCoins'),
            const SizedBox(height: 8),
            Text('Seu saldo: $moedas StairCoins'),
            if (!saldoSuficiente) ...[
              const SizedBox(height: 12),
              const Text(
                'Saldo insuficiente para realizar esta compra.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: saldoSuficiente
                ? () async {
                    if (alunoId == null) return;
                    final produtoProvider = Provider.of<ProdutoProvider>(
                        scaffoldContext,
                        listen: false);
                    final authProvider = Provider.of<AuthProvider>(
                        scaffoldContext,
                        listen: false);
                    final codigo = await produtoProvider.trocarProduto(
                      produtoId: produto.id,
                      alunoId: alunoId,
                      moedasAluno: moedas,
                      authProvider: authProvider,
                    );
                    Navigator.of(ctx).pop();
                    if (codigo == 'MOEDAS_INSUFICIENTES') {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Moedas insuficientes!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (codigo != null) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text('Troca realizada! Código: $codigo'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Erro ao realizar troca.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,
            child: const Text('Confirmar Compra'),
          ),
        ],
      ),
    );
  }
}
