import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String,dynamic> _lastRemoved;
  int _lastRemovedPos;

  final _taskController = TextEditingController();

  @override //funcao ja existente no State
  void initState() {//funcao que carrega dados enquanto o app inicia
    super.initState();

    _readData().then((data) {//quando o arquivo for recebido
      setState(() {
        _toDoList = json.decode(data); //ele coloca a string do arquivo convertida em json na lista
      });
    }); //o then eh para chamar acoes assim que o arquivo for lido, pois ele eh do futuro
  }

  void _addToDo() {
    setState(() {
      //atualizar a tela
      Map<String, dynamic> newToDo = Map(); //normalmente o tipo para json eh string e dynamic
      newToDo["title"] = _taskController.text;
      _taskController.text = ""; //zera o campo depois que pegar o dado
      newToDo["ok"] = false;
      _toDoList.add(newToDo); //adiciona o mapa na lista
      _saveData();
    });
  }

  Future<Null> _refresh() async{ //atualiza e ordena as tarefas
    await Future.delayed(Duration(seconds: 1)); //faz com que espere um segundo 

    setState(() {
      _toDoList.sort((a,b){ //passa uma funcao para ordenacao, retornando 1 se a for "maior" que b, 0 se for igual e -1 se for menor
      if(a["ok"] && !b["ok"]) return 1;
      else if(!a["ok"] && b["ok"]) return -1;
      else return 0;
      
    });

      _saveData();          
    });

    return null;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
          child: Row(
            children: <Widget>[
              Expanded(//faz com que o widget dentro dele se expanda o maximo possivel
                child: TextField(
                  decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                  controller: _taskController,
                ),
              ),
              RaisedButton(
                color: Colors.blueAccent,
                child: Text("Add"),
                textColor: Colors.white,
                onPressed: _addToDo,
              )
            ],
          ),
        ),
        Expanded(//Como nao se sabe a largura exata, usa o expanded pra se expandir o max possivel
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              //listView eh um widget que pode fazer uma lista, o builder eh um construtor que permite que construa a lista de acordo com que for rodando
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _toDoList.length, //especifica a quantidade de itens que tem na lista
              itemBuilder: buildItem),
          ), //item builder cria os elementos da lista
        ),
      ]),
    );
  }

  Widget buildItem(BuildContext context,int index) {
    return Dismissible( //widget que vai permitir que arraste o widget e delete ele
      key:Key(DateTime.now().millisecondsSinceEpoch.toString()), //string que vai definir qual elemento eh esse dismissible. Nesse caso ele pega o tempo em ms 
      background: Container(//o background eh oq diz o que vai aparecer atras quando deslizar o widget
        color: Colors.red,
        child: Align(//o align eh para fazer com que o icone apareca no canto que eu quero
          alignment: Alignment(-0.9,0.0), //as coord vao de -1 a 1 em x e em y, ou seja, para o centro sera 0 e 0
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction:DismissDirection.startToEnd, //direcao de onde sera o deslizamento
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar( //aqui pode colocar um widget que vai ficar no canto oposto. O circle avatar eh o circulo de perfil
          child: Icon(_toDoList[index]["ok"] ? //verifica se a tarefa foi concluida pra mostrar os icones
              Icons.check : Icons.error),
        ),
        onChanged: (c) {//c eh o parametro que retorna true ou false para se marcou ou nao
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          _lastRemoved= Map.from(_toDoList[index]); //duplicar o elemento 
          _lastRemovedPos=index;
          _toDoList.removeAt(index);

          _saveData(); //salva a lista com ele removido

          final snack = SnackBar( //mensagem que aparece no fim da tela com uma acao opcional e uma informacao
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action:SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();                  
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack); //mostra a snackbar
        });
      }, // onDismissed
    );
  }

  Future<File> _getFile() async {
    //pegar um arquivo no celular
    final directory =
        await getApplicationDocumentsDirectory(); //pega o local onde pode armazenar os docs do app
    return File(
        "${directory.path}/data.json"); //abre o arquivo no diretorio dos docs
  }

  Future<File> _saveData() async {
    String data = json.encode(
        _toDoList); //pega a lista e transforma num json e armazena numa string

    final file = await _getFile(); //pega o arquivo
    return file.writeAsString(data); //escreve no arquivo os dados da lista
  }

  Future<String> _readData() async {
    try {
      //tenta ler o arquivo
      final file = await _getFile(); //pega o arquivo
      return file.readAsString(); //le o arquivo
    } catch (e) { //Caso nao aconteca nada retorna nulo
      return null;
    }
  }
}
