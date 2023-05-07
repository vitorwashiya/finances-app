import 'package:flutter/material.dart';
import 'package:orcas_finance/models/cost.dart';

class AddCostPage extends StatefulWidget {
  const AddCostPage({Key? key}) : super(key: key);

  @override
  _AddCostPageState createState() => _AddCostPageState();
}

class _AddCostPageState extends State<AddCostPage> {
  late TextEditingController _valueController;

  Map<String, List<String>> categorySubCategoryMap = {
    "Essencial": ["Alimento", "Transporte"],
    "Lazer": ["Alimento", "Bar"],
  };
  late String _selectedCategory;
  late String _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    _selectedCategory = categorySubCategoryMap.keys.first;
    categorySubCategoryMap[_selectedCategory]!.isNotEmpty
        ? _selectedSubcategory =
            categorySubCategoryMap[_selectedCategory]!.first
        : "";
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

  Widget _createDropdown(bool catBool) {
    List<DropdownMenuItem<String>> dropdownItems = [];

    if (catBool) {
      dropdownItems = categorySubCategoryMap.keys.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList();
    } else {
      dropdownItems =
          categorySubCategoryMap[_selectedCategory]!.map((String subcategory) {
        return DropdownMenuItem<String>(
          value: subcategory,
          child: Text(subcategory),
        );
      }).where((item) {
        final values = categorySubCategoryMap[_selectedCategory]!;
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
                    _selectedCategory = catBool ? newValue : _selectedCategory;
                    _selectedSubcategory = catBool
                        ? categorySubCategoryMap[newValue]!.isNotEmpty
                            ? categorySubCategoryMap[newValue]!.first
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
                      ? categorySubCategoryMap.remove(_selectedCategory)
                      : categorySubCategoryMap[_selectedCategory]!
                          .remove(_selectedSubcategory);
                  if (categorySubCategoryMap.keys.isEmpty) {
                    categorySubCategoryMap = {
                      "": [""]
                    };
                    _selectedCategory = "";
                  } else {
                    _selectedCategory = catBool
                        ? categorySubCategoryMap.keys.first
                        : _selectedCategory;
                  }

                  if (categorySubCategoryMap[_selectedCategory]!.isEmpty) {
                    categorySubCategoryMap[_selectedCategory] = [""];
                  }
                  _selectedSubcategory =
                      categorySubCategoryMap[_selectedCategory]!.first;
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
                      categorySubCategoryMap[newName!] = [""];
                      _selectedCategory = newName!;
                      _selectedSubcategory = "";
                    } else {
                      if (categorySubCategoryMap[_selectedCategory]!.length ==
                              1 &&
                          categorySubCategoryMap[_selectedCategory]!.first ==
                              "") {
                        categorySubCategoryMap[_selectedCategory] = [newName!];
                      } else {
                        categorySubCategoryMap[_selectedCategory]!
                            .add(newName!);
                      }
                      _selectedSubcategory = newName!;
                    }
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
