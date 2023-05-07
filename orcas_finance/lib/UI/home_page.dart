import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:orcas_finance/UI/add_cost_page.dart';
import 'package:orcas_finance/models/cost.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> monthNames = [
    "Janeiro",
    "Fevereiro",
    "Agosto",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ];

  List<Cost> _costList = [];
  final List<Cost> _groupedCostList = [];
  int _currentIndex = 0;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCostList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            _updateGroupedCostList(_costList);
          },
          icon: const Icon(
            Icons.refresh,
            size: kTextTabBarHeight,
          ),
        ),
        title: const Text("Orcas Finance"),
        backgroundColor: Colors.red,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 10.0,
            ),
            for (var cost in _currentIndex == 0 ? _groupedCostList : _costList)
              _createCard(cost),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () async {
          var newCost = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCostPage()),
          );
          setState(() {
            if (newCost != null) {
              _costList.add(newCost);
              _applyFilter(startDate, endDate);
              _saveCostList(_costList);
            }
          });
        },
        child: const Icon(
          Icons.add,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Grouped List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Individual List',
          ),
        ],
      ),
    );
  }

  void _updateGroupedCostList(List<Cost> costList) {
    final groupedCostMap = groupBy<Cost, String>(
      costList,
      (cost) =>
          '${cost.dateCost.year}-${cost.dateCost.month}-${cost.categoryName}-${cost.subcategory}',
    );

    final groupedCostList = groupedCostMap.entries.map((entry) {
      final keyParts = entry.key.split('-');
      final year = int.parse(keyParts[0]);
      final month = int.parse(keyParts[1]);
      final categoryName = keyParts[2];
      final subcategory = keyParts[3];

      final sum = entry.value.fold<double>(
        0,
        (previousValue, cost) => previousValue + cost.value,
      );

      return Cost(
        dateCost: DateTime(year, month),
        categoryName: categoryName,
        subcategory: subcategory,
        value: sum,
      );
    }).toList();
    setState(() {
      _groupedCostList.clear();
      _groupedCostList.addAll(groupedCostList);
    });
  }

  Future<void> _saveCostList(List<Cost> costList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> costJsonList =
        costList.map((cost) => json.encode(cost.toJson())).toList();
    prefs.setStringList('costList', costJsonList);
  }

  Future<void> _loadCostList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> costJsonList = prefs.getStringList('costList') ?? [];
    setState(() {
      _costList = costJsonList
          .map((jsonString) => Cost.fromJson(json.decode(jsonString)))
          .toList();
      _updateGroupedCostList(_costList);
    });
  }

  Future<DateTime?> _selectDate(
      BuildContext context, DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    return picked;
  }

  void _applyFilter(DateTime? startDate, DateTime? endDate) {
    List<Cost> filteredCostList = _costList.where((cost) {
      return cost.dateCost
              .isAfter(startDate!.subtract(const Duration(days: 1))) &&
          cost.dateCost.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _updateGroupedCostList(filteredCostList);
    });
  }

  void _showFilterDialog() {
    _startDateController.text = "${startDate.toLocal()}".split(' ')[0];
    _endDateController.text = "${endDate.toLocal()}".split(' ')[0];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filtrar por data"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Apenas visão agrupada*",
                style: TextStyle(fontSize: 10.0),
              ),
              const Text("Data inicial"),
              const SizedBox(height: 8),
              ListTile(
                title: TextField(
                  controller: _startDateController,
                  enabled: false,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                onTap: () async {
                  final selectedDate = await _selectDate(context, startDate);
                  if (selectedDate != null) {
                    setState(() {
                      startDate = selectedDate;
                      _startDateController.text =
                          "${startDate.toLocal()}".split(' ')[0];
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text("Data Final"),
              const SizedBox(height: 8),
              ListTile(
                title: TextField(
                  controller: _endDateController,
                  enabled: false,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                onTap: () async {
                  final selectedDate = await _selectDate(context, endDate);
                  if (selectedDate != null) {
                    setState(() {
                      endDate = selectedDate;
                      _endDateController.text =
                          "${endDate.toLocal()}".split(' ')[0];
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Filtrar"),
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilter(startDate, endDate);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _createCard(Cost cost) {
    if (_currentIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
        child: Card(
          color: Color.fromARGB(255, 241, 201, 116),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    "Mês Referência: ${monthNames[cost.dateCost.month - 1]}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${cost.categoryName} - ${cost.subcategory}"),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Text(
              "R\$${cost.value}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            setState(() {
              _costList.remove(cost);
              _applyFilter(startDate, endDate);
              _saveCostList(_costList);
            });
          },
          child: Card(
            color: Color.fromARGB(255, 241, 201, 116),
            child: ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Mês Referência: ${monthNames[cost.dateCost.month - 1]}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${cost.categoryName} - ${cost.subcategory}"),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: Text(
                "R\$${cost.value}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
