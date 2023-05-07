import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orcas_finance/models/cost.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCostPage extends StatefulWidget {
  const AddCostPage({Key? key}) : super(key: key);

  @override
  _AddCostPageState createState() => _AddCostPageState();
}

class _AddCostPageState extends State<AddCostPage> {
  late TextEditingController _valueController;

  Map<String, List<String>> _categorySubCategoryMap = {};
  late String _selectedCategory = "";
  late String _selectedSubcategory = "";

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    _loadCategorySubCategoryMap().then((value) {
      setState(() {
        _categorySubCategoryMap = value;
        _selectedCategory = _categorySubCategoryMap.keys.first;
        _selectedSubcategory =
            _categorySubCategoryMap[_selectedCategory]!.isNotEmpty
                ? _categorySubCategoryMap[_selectedCategory]!.first
                : "";
      });
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orcas Finance"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              _createDropdown(true),
              const SizedBox(
                height: 10.0,
              ),
              _createDropdown(false),
              const SizedBox(
                height: 10.0,
              ),
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          Cost cost = Cost(
            dateCost: DateTime.now(),
            categoryName: _selectedCategory,
            subcategory: _selectedSubcategory,
            value: double.parse(_valueController.text.replaceAll(',', '.')),
          );
          Navigator.pop(context, cost);
        },
        child: const Icon(
          Icons.save,
        ),
      ),
    );
  }

  Future<void> _saveCategorySubCategoryMap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedMap = json.encode(_categorySubCategoryMap);
    prefs.setString('categorySubCategoryMap', encodedMap);
  }

  Future<Map<String, List<String>>> _loadCategorySubCategoryMap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedMap = prefs.getString('categorySubCategoryMap');
    if (encodedMap != null) {
      final decodedMap = json.decode(encodedMap) as Map<String, dynamic>;
      return Map<String, List<String>>.fromEntries(decodedMap.entries
          .map((e) => MapEntry(e.key, List<String>.from(e.value))));
    } else {
      return {
        "Essencial": ["Alimento", "Transporte"],
        "Lazer": ["Alimento", "Bar"],
      };
    }
  }

  Widget _createDropdown(bool catBool) {
    return FutureBuilder(
      future: _loadCategorySubCategoryMap(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          {
            List<DropdownMenuItem<String>> dropdownItems = [];

            if (catBool) {
              dropdownItems =
                  _categorySubCategoryMap.keys.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList();
            } else {
              dropdownItems = _categorySubCategoryMap[_selectedCategory]!
                  .map((String subcategory) {
                return DropdownMenuItem<String>(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).where((item) {
                final values = _categorySubCategoryMap[_selectedCategory]!;
                final set = Set.of(values);
                return set.contains(item.value) &&
                    !set
                        .skipWhile((value) => value != item.value)
                        .skip(1)
                        .contains(item.value);
              }).toList();
            }

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: catBool ? _selectedCategory : _selectedSubcategory,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory =
                                catBool ? newValue : _selectedCategory;
                            _selectedSubcategory = catBool
                                ? _categorySubCategoryMap[newValue]!.isNotEmpty
                                    ? _categorySubCategoryMap[newValue]!.first
                                    : ""
                                : newValue;
                          });
                        }
                      },
                      items: dropdownItems,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          catBool
                              ? _categorySubCategoryMap
                                  .remove(_selectedCategory)
                              : _categorySubCategoryMap[_selectedCategory]!
                                  .remove(_selectedSubcategory);
                          if (_categorySubCategoryMap.keys.isEmpty) {
                            _categorySubCategoryMap = {
                              "": [""]
                            };
                            _selectedCategory = "";
                          } else {
                            _selectedCategory = catBool
                                ? _categorySubCategoryMap.keys.first
                                : _selectedCategory;
                          }

                          if (_categorySubCategoryMap[_selectedCategory]!
                              .isEmpty) {
                            _categorySubCategoryMap[_selectedCategory] = [""];
                          }
                          _selectedSubcategory =
                              _categorySubCategoryMap[_selectedCategory]!.first;

                          _saveCategorySubCategoryMap();
                        });
                      },
                      icon: const Icon(
                        Icons.delete,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        _showAddPopup(catBool);
                      },
                      icon: const Icon(
                        Icons.add,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  void _showAddPopup(bool isCategory) {
    String? newName;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar ${isCategory ? 'Categoria' : 'Subcategoria'}'),
          content: TextField(
            onChanged: (value) => newName = value.trim(),
            decoration: InputDecoration(
              hintText:
                  'Digite o nome da ${isCategory ? 'Categoria' : 'Subcategoria'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newName != null && newName!.isNotEmpty) {
                  setState(() {
                    if (isCategory) {
                      if (_categorySubCategoryMap.keys.length == 1 &&
                          _categorySubCategoryMap.keys.first == "") {
                        _categorySubCategoryMap = {
                          newName!: [""]
                        };
                      } else {
                        _categorySubCategoryMap[newName!] = [""];
                      }
                      _selectedCategory = newName!;
                      _selectedSubcategory = "";
                    } else {
                      if (_categorySubCategoryMap[_selectedCategory]!.length ==
                              1 &&
                          _categorySubCategoryMap[_selectedCategory]!.first ==
                              "") {
                        _categorySubCategoryMap[_selectedCategory] = [newName!];
                      } else {
                        _categorySubCategoryMap[_selectedCategory]!
                            .add(newName!);
                      }
                      _selectedSubcategory = newName!;
                    }
                    _saveCategorySubCategoryMap();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
