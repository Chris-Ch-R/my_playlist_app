import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> musics = [];

  final assetsAudioPlayer = AssetsAudioPlayer();

  late Future<List<Audio>> getMusic;

  @override
  void initState() {
    getMusic = _initMusics();
    super.initState();
  }

  Future<List<Audio>> _initMusics() async {
    // >> To get paths you need these 2 lines
    final manifestContent = await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    // >> To get paths you need these 2 lines

    print(manifestMap.keys);

    final musicPaths = manifestMap.keys
        .where((String key) => key.contains('musics/'))
        .toList();
    print("===========");
    print(musicPaths);


    List<Audio> playlist = [];
    for(var musicPath in musicPaths){
      playlist.add(Audio(musicPath));
    }
    assetsAudioPlayer.open(
      Playlist(
          audios: playlist
      ),
      loopMode: LoopMode.playlist,
      autoStart: false,
      showNotification: false,
    );
    // assetsAudioPlayer.playlist.audios
    return playlist;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My playlist"),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Audio>>(
              future: getMusic,
              builder: (context, snapshot) {
                if(snapshot.hasData){
                  return Column(
                    children: [
                      StreamBuilder(
                          stream: assetsAudioPlayer.current,
                          builder: (context, asyncSnapshot) {
                            final Playing? currentSong = asyncSnapshot.data;
                            if(currentSong != null) {
                              final musicData = currentSong.audio.assetAudioPath.split('/').last.split('-');
                              final musicName = musicData.last;
                              final musicBy = musicData[0].replaceAll('_', ' ');
                              final imagePath = "assets/images/${currentSong.audio.assetAudioPath.split('/').last.replaceAll('.mp3', '.jpg')}";
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0 , vertical: 10.0),
                                child: Column(
                                    children: [
                                      Hero(
                                          tag: 'dash',
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                                child: Image.asset(imagePath ,height: MediaQuery.of(context).size.height * 0.25,)),
                                          )
                                      ),
                                      Text(musicName.split('.')[0] , style: const TextStyle(fontSize: 20 , fontWeight: FontWeight.bold),),
                                      Text(musicBy),
                                    ],
                                  ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                      ),
                      StreamBuilder(
                          stream: assetsAudioPlayer.currentPosition,
                          builder: (context, asyncSnapshot) {
                            final Duration? currentPosition = asyncSnapshot.data;
                            if((assetsAudioPlayer.current.hasValue && assetsAudioPlayer.current.value != null) && currentPosition != null) {
                              final duration = assetsAudioPlayer.current.value!.audio.duration;
                              return Column(
                                children: [
                                  Slider(
                                    max: duration.inSeconds.toDouble(),
                                    value: currentPosition.inSeconds.toDouble(),
                                    onChanged: (double value) {},
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children:[
                                        Text("${NumberFormat("00").format(currentPosition.inMinutes)}:${NumberFormat("00").format((currentPosition.inSeconds%60).toInt())}"),
                                        Text("${NumberFormat("00").format(duration.inMinutes)}:${NumberFormat("00").format((duration.inSeconds%60).toInt())}"),
                                      ]
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          }
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(onPressed: (){}, icon: const Icon(Icons.favorite , color: Colors.red,)),
                          IconButton(onPressed: (){
                            try{
                              if(assetsAudioPlayer.current.value?.audio.audio == snapshot.data?[0]){
                                if(assetsAudioPlayer.currentPosition.hasValue){
                                  assetsAudioPlayer.playlistPlayAtIndex(0);
                                }
                              }else{
                                assetsAudioPlayer.previous();
                              }
                            } catch (e){
                              print(e.toString());
                            }
                          }, icon: const Icon(Icons.skip_previous)),
                          IconButton(onPressed: () async{
                              if(assetsAudioPlayer.isPlaying.value){
                                await assetsAudioPlayer.pause();
                              } else {
                                await assetsAudioPlayer.play();
                              }
                              setState(() {});
                          }, icon: assetsAudioPlayer.isPlaying.value ? const Icon(Icons.pause_circle) : const Icon(Icons.play_circle),
                            iconSize: 60,
                          ),
                          IconButton(onPressed: (){
                            assetsAudioPlayer.next();
                          }, icon: const Icon(Icons.skip_next)),
                          IconButton(onPressed: (){
                            setState(() {
                              if(assetsAudioPlayer.loopMode.value == LoopMode.single){
                                assetsAudioPlayer.setLoopMode(LoopMode.playlist);
                              } else{
                                assetsAudioPlayer.setLoopMode(LoopMode.single);
                              }
                            });
                          }, icon: assetsAudioPlayer.loopMode.value == LoopMode.single ? const Icon(Icons.repeat_one) :
                            const Icon(Icons.repeat)),

                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final musicData = snapshot.data![index].path.split('/').last.split('-');
                            final musicName = musicData.last;
                            final musicBy = musicData[0].replaceAll('_', ' ');
                            final imagePath = "assets/images/${snapshot.data![index].path.split('/').last.replaceAll('.mp3', '.jpg')}";
                            return ListTile(
                              leading: Image.asset(imagePath),

                              title: Text(musicName.split('.')[0], maxLines: 1,),
                              subtitle: Text(musicBy, maxLines: 1,),

                              trailing: assetsAudioPlayer.current.hasValue && assetsAudioPlayer.current.value?.audio.audio == snapshot.data![index] ? const Text("playing") : const Icon(Icons.play_circle_outline),

                              onTap: () async {
                                await assetsAudioPlayer.playlistPlayAtIndex(index);
                                setState(() {

                                });
                              },
                            );
                          },
                        ),
                      )
                    ],

                  );
                }

                return const Center(child: Text("no data."));

              }
            ),
          ),
        ],
      ),
    );
  }
}
