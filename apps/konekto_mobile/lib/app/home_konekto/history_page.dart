import 'package:flutter/material.dart';

// Modelo de dados para um item do histórico de hotéis e promoções
class HistoryEntry {
  final String hotelName;
  final String stayDates;
  final String details;

  const HistoryEntry({
    required this.hotelName,
    required this.stayDates,
    required this.details,
  });
}

class HistoryPage extends StatelessWidget {
  HistoryPage({super.key});

  // Lista mock de dados. Em uma aplicação real, estes dados viriam da API.
  final List<HistoryEntry> historyItems = const [
    HistoryEntry(
      hotelName: 'Grand Plaza Hotel',
      stayDates: '22 de maio - 25 de maio',
      details: 'Promoção: 20% de desconto em serviço de quarto',
    ),
    HistoryEntry(
      hotelName: 'Sunset Resort & Spa',
      stayDates: '18 de maio - 20 de maio',
      details: 'Valor: 25% de desconto em massagens',
    ),
    HistoryEntry(
      hotelName: 'Ocean View Residence',
      stayDates: '15 de maio - 17 de maio',
      details: 'Promoção: Pacote família com cortesia para crianças',
    ),
    HistoryEntry(
      hotelName: 'Urban Boutique Hotel',
      stayDates: '10 de maio - 12 de maio',
      details: 'Valor: Late checkout sem custo adicional',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF8),
      appBar: AppBar(
        // Remove o botão de voltar automaticamente
        automaticallyImplyLeading: false, 
        title: const Text(
          'Histórico',
          style: TextStyle(
            color: Color(0xFF111416),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        // O espaçamento vertical foi aumentado aqui
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          final item = historyItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: HistoryItem(item: item),
          );
        },
      ),
    );
  }
}

class HistoryItem extends StatelessWidget {
  final HistoryEntry item;

  const HistoryItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.hotelName,
            style: const TextStyle(
              color: Color(0xFF111416),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.stayDates,
            style: const TextStyle(
              color: Color(0xFF5E728C),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.details,
            style: const TextStyle(
              color: Color(0xFF111416),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}