include "console.iol"
include "AdministratorInterface.iol"
include "Time.iol"
include "string_utils.iol"
include "math.iol"



outputPort ShopPort1 {
	Location: "socket://localhost:61231"
	Protocol: sodep
	Interfaces: AdministratorInterface
}
outputPort ShopPort2 {
	Location: "socket://localhost:61232"
	Protocol: sodep
	Interfaces: AdministratorInterface
}
outputPort ShopPort3 {
	Location: "socket://localhost:61233"
	Protocol: sodep
	Interfaces: AdministratorInterface
}
outputPort ShopPort4 {
	Location: "socket://localhost:61234"
	Protocol: sodep
	Interfaces: AdministratorInterface
}
outputPort ShopPort5 {
	Location: "socket://localhost:61236"
	Protocol: sodep
	Interfaces: AdministratorInterface
}

/*
Inizialmente carico all'interno dello Shop quattro prodotti predefiniti con le loro relative quantità.
*/
init
{
	with( global.listaProdotti ){
    .oggetto[0].nome = "Banana";
    .oggetto[0].quantita = 50;
    .oggetto[1].nome = "Cocomero";
    .oggetto[1].quantita = 50;
    .oggetto[2].nome = "Carota";
    .oggetto[2].quantita = 50;
    .oggetto[3].nome = "Insalata";
    .oggetto[3].quantita = 50
  };
	keepRunning = true
}


main
{
	println@Console("Benvenuto nell'ADMINISTRATOR")();


	//random@Math()(rnd);
	//global.currentSending = int(rnd*5);
	global.currentSending = 1; //la prima volta invio al server 1, magari un random
	global.response.status = 0;
	//sleep@Time(2000)();

	/*
	Eseguo il while finchè l'operazione richiesta non è stata eseguita.
	status è un intero che risulta = 100 se l'operazione è stata eseguita sul server leader.
	Se il server con cui si sta comunicando non è il server leader, allora esso restituirà
	la variabile status con all'interno l'ID del server leader.
	*/
	while(global.response.status!=100){
		scope( scope_caricaProdotti )
		{
		  	install(
		  		ServerOffline => {
						println@Console("\t\t IOException server from scope 1")()
		  			//global.currentSending ++
					},
		  		IOException => {
		  			println@Console("\t\t IOException, il SERVER non e' attivo")();
		  			global.currentSending ++;
		  			//Se il current sending diventa 6 ripartiamo a inviare la richiesta dal server 1
		  			if( global.currentSending == 6 ) {
		  				global.currentSending = 1
		  			}
		  		},
		  		ConnectException => { println@Console("\t\t IOException server from scope 3")() }
		 	);

			println@Console("currentSending: "+global.currentSending+"    status: "+global.response.status )();
			sleep@Time(1000)();
			if(global.currentSending == 1){
				println@Console( "Invio a SERVER 1" )();
				caricaProdotti@ShopPort1(global.listaProdotti)(global.response)
			} else if( global.currentSending == 2 ) {
				println@Console( "Invio a SERVER 2" )();
				caricaProdotti@ShopPort2(global.listaProdotti)(global.response)
			} else if( global.currentSending == 3 ) {
				println@Console( "Invio a SERVER 3" )();
				caricaProdotti@ShopPort3(global.listaProdotti)(global.response)
			} else if( global.currentSending == 4 ) {
				println@Console( "Invio a SERVER 4" )();
				caricaProdotti@ShopPort4(global.listaProdotti)(global.response)
			} else if( global.currentSending == 5 ) {
				println@Console( "Invio a SERVER 5" )();
				caricaProdotti@ShopPort5(global.listaProdotti)(global.response)
			};
			//Vuol dire che non c'è nessun server leader
			if( global.response.status == 0 ) {
				global.currentSending++
				//global.response.status = global.currentSending
			}
			else{
				//println@Console( "Dentro all'else" )();
				global.currentSending = global.response.status
			};
			println@Console( global.response.message )()
			//global.currentSending ++
		}
	};




	println@Console(response.message)();
	println@Console("Operazioni disponibili:
	1 - Aggiungere una quantita di un prodotto all'interno dello Shop
	2 - Eliminare una quantita di un prodotto all'interno dello ShopPort
	3 - Terminare il processo dell'Administrator")();
	registerForInput@Console()();


	while(keepRunning){
		in(operazione);
		//Aggiungo una quantita di un prodotto all'interno dello Shop
		if(operazione == 1){
			println@Console("Inserisci il nome del prodotto da aggiungere (senza spazi)")();
			in(nomeNuovoProdotto);
			println@Console("Inserisci la quantita' di prodotto da aggiungere")();
			in(quantitaNuovoProdotto);
			request.nome = nomeNuovoProdotto;
			request.quantita = int(quantitaNuovoProdotto);

			global.currentSending = 1; //la prima volta invio al server 1, magari un random
			global.response.status = -1;

			//eseguire il controllo fatto prima per il caricaProdotto
			while(global.response.status!=100){
				scope( scope_aggiungiProdotto )
				{
	  			install(
	  				ServerOffline => { println@Console("\t\t IOException server from scope 1")() },
	  				IOException => {
		  				println@Console("\t\t IOException, il SERVER non e' attivo")();
		  				global.currentSending ++;
		  				//Se il current sending diventa 6 ripartiamo a inviare la richiesta dal server 1
		  				if( global.currentSending == 6 ) {
		  					global.currentSending = 1
		  				}
		  			},
	  				ConnectException => { println@Console("\t\t IOException server from scope 3")() }
	 			);
				println@Console("currentSending: "+global.currentSending+"    status: "+global.response.status )();
				sleep@Time(1000)();
				if(global.currentSending == 1){
					println@Console( "Invio a SERVER 1" )();
					aggiungiProdotto@ShopPort1(request)(global.response)
				} else if( global.currentSending == 2 ) {
					println@Console( "Invio a SERVER 2" )();
					aggiungiProdotto@ShopPort2(request)(global.response)
				} else if( global.currentSending == 3 ) {
					println@Console( "Invio a SERVER 3" )();
					aggiungiProdotto@ShopPort3(request)(global.response)
				} else if( global.currentSending == 4 ) {
					println@Console( "Invio a SERVER 4" )();
					aggiungiProdotto@ShopPort4(request)(global.response)
				} else if( global.currentSending == 5 ) {
					println@Console( "Invio a SERVER 5" )();
					aggiungiProdotto@ShopPort5(request)(global.response)
				};
				if( global.response.status == 0 ) {
					global.currentSending++
					//global.response.status = global.currentSending
				}else{
					global.currentSending = global.response.status
				};
				println@Console( global.response.message )()
			}
		};
		println@Console("Si desidera effettuare un'altra operazione? (1, 2, 3)")()
	}
		//Elimino una quantita di un prodotto all'interno dello ShopPort
		else if(operazione == 2){
			println@Console("Inserisci il nome del prodotto da eliminare (senza spazi)")();
			in(nomeNuovoProdotto);
			println@Console("Inserisci la quantita' di prodotto da eliminare")();
			in(quantitaNuovoProdotto);
			request.nome = nomeNuovoProdotto;
			request.quantita = int(quantitaNuovoProdotto);


			//eseguire il controllo fatto prima per il caricaProdotto

			global.currentSending = 1; //la prima volta invio al server 1, magari un random
			global.response.status = -1;

			while(global.response.status!=100){
				scope( scope_eliminaProdotto )
				{
	  				install(
	  					ServerOffline => { println@Console("\t\t IOException server from scope 1")() },
	  					IOException => {
		  					println@Console("\t\t IOException, il SERVER non e' attivo")();
		  					global.currentSending ++;
		  					//Se il current sending diventa 6 ripartiamo a inviare la richiesta dal server 1
		  					if( global.currentSending == 6 ) {
		  						global.currentSending = 1
		  					}
		  				},
	  					ConnectException => { println@Console("\t\t IOException server from scope 3")() }
	 				);
					println@Console("currentSending: "+global.currentSending+"    status: "+global.response.status )();
					sleep@Time(1000)();
					if(global.currentSending == 1){
						println@Console( "Invio a SERVER 1" )();
						eliminaProdotto@ShopPort1(request)(global.response)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						eliminaProdotto@ShopPort2(request)(global.response)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						eliminaProdotto@ShopPort3(request)(global.response)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						eliminaProdotto@ShopPort4(request)(global.response)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						eliminaProdotto@ShopPort5(request)(global.response)
					};
					if( global.response.status == 0 ) {
						global.currentSending++
						//global.response.status = global.currentSending
					}
					else{
						global.currentSending = global.response.status
					};

					println@Console( global.response.message )()
				}
			};
			println@Console("Si desidera effettuare un'altra operazione? (1, 2, 3)")()
		}
		//Termina il processo dell'Administrator
		else if(operazione == 3){
			keepRunning = false
		}
		//Se il numero digitato è diverso dalle opzioni disponibili, si invia un messaggio di errore.
		else{
			println@Console("ERRORE: Operazione non disponibile.")()
		}
		//Chiedo quale operazione si vuole effettuare fino a quando
		//non si decide di terminare il flusso di vita dell'Administrator


	}//end while





}
