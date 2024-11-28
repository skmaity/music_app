import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
              const SizedBox(height: 10,),
        
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Padding(
                padding: EdgeInsets.only(right: 10,top: 40),
                child: Text('Playlists',style: TextStyle(fontSize: 45,color: Colors.white),),
              ),
              SizedBox(width: 10,)
              ],),

              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GridView.builder(
                  itemCount: 2,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                  itemBuilder: (context, index) {
                    if(index == 0){
return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){

                        },
                        child: Container(
                                          
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                             color: Colors.grey.shade100.withOpacity(0.4)
                            ),
                            borderRadius: BorderRadius.circular(20),
                           color: Colors.grey.shade100.withOpacity(0.2)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesome.heart,color: Colors.red,),
                              SizedBox(height: 20,),
                              Text('My Faviorate',style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    );
                    }
                    else if (index == 2-1){
                      return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){

                        },
                        child: Container(
                                          
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                             color: Colors.grey.shade100.withOpacity(0.4)
                            ),
                            borderRadius: BorderRadius.circular(20),
                           color: Colors.grey.shade100.withOpacity(0.2)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,color: Colors.white,),
                              SizedBox(height: 20,),
                              Text('Add Playlist',style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    );
                    }
                    else{
                      return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){

                        },
                        child: Container(
                                          
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                             color: Colors.grey.shade100.withOpacity(0.4)
                            ),
                            borderRadius: BorderRadius.circular(20),
                           color: Colors.grey.shade100.withOpacity(0.2)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesome.heart,color: Colors.red,),
                              SizedBox(height: 20,),
                              Text('My Faviorate',style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    );
                    }
                    
                    
                  },
                ),
              )
            
          ],
        ),
      )
    );
  }
}