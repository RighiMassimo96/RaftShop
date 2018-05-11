include "console.iol"
include "string_utils.iol"
include "ClientInterface.iol"
include "Time.iol"
include "math.iol"



outputPort ShopPort1 {
	Location: "socket://localhost:61231"
	Protocol: sodep
	Interfaces: ClientInterface
}
outputPort ShopPort2 {
	Location: "socket://localhost:61232"
	Protocol: sodep
	Interfaces: ClientInterface
}
outputPort ShopPort3 {
	Location: "socket://localhost:61233"
	Protocol: sodep
	Interfaces: ClientInterface
}
outputPort ShopPort4 {
	Location: "socket://localhost:61234"
	Protocol: sodep
	Interfaces: ClientInterface
}
outputPort ShopPort5 {
	Location: "socket://localhost:61236"
	Protocol: sodep
	Interfaces: ClientInterface
}



init
{
  keepRunning = true
}
main
{
	println@Console("'BENVENUTO IN RAFT SHOP'
		
Digitare il numero dell'operazione da eseguire:
1 - Creare un carrello
2 - Visualizzare la lista degli oggetti presenti nello Shop
3 - Cancellare un carrello
4 - Acquistare un carrello
5 - Aggiungere elementi nel carrello
6 - Rimuovi elementi dal carrello
7- Termina il client
	")();
	registerForInput@Console()(); //Il client riceve l'input da tastiera


	while(keepRunning){
		in(operazione);

		/*
		Richiedo la creazione di un carrello all'interno del server.
		*/
		if(operazione == 1){
			println@Console("\nDigitare il nome del carrello da creare (senza spazi): ")();
			in(request.nome);

			global.currentSending = 1; 
			global.response.status = -1;

			while(global.response.status!=100){
				scope( scope_creaCarrello )
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
						creaCarrello@ShopPort1(request)(global.response)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						creaCarrello@ShopPort2(request)(global.response)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						creaCarrello@ShopPort3(request)(global.response)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						creaCarrello@ShopPort4(request)(global.response)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						creaCarrello@ShopPort5(request)(global.response)
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

			//creaCarrello@ShopPort(request)(response);
			//println@Console(response.message)();
			println@Console("Si desidera effettuare un altra operazione?(Digitare il numero dell'operazione)")()
		}
		/*
		Richiedo di visualizzare la lista degli oggetti presenti nello Shop
		*/
		else if(operazione == 2){

			global.currentSending = 1; 
			global.response.status = -1;

			while(global.response.status!=100){
				scope( scope_vediListaOggetti )
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
						vediListaOggetti@ShopPort1(2)(global.response)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						vediListaOggetti@ShopPort2(2)(global.response)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						vediListaOggetti@ShopPort3(2)(global.response)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						vediListaOggetti@ShopPort4(2)(global.response)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						vediListaOggetti@ShopPort5(2)(global.response)
					};
					if( global.response.status == 0 ) {
						global.currentSending++
						//global.response.status = global.currentSending
					}else{
						global.currentSending = global.response.status
					};

					println@Console( global.response.message )();
					for(i=0, i<#global.response.listaShop.oggetto, i++){
    					println@Console("Merce: "+global.response.listaShop.oggetto[i].nome+"\t -> \tQuantita: "+global.response.listaShop.oggetto[i].quantita)()
    				}
				}
			};
			
			println@Console("Si desidera effettuare un altra operazione?(Digitare il numero dell'operazione)")()
 		}
 		/*
 		Richiedo la cancellazione di un carrello
 		*/
 		else if(operazione == 3){
 			println@Console("\nDigitare il nome del carrello da cancellare: ")();
			in(request.nome);

			global.currentSending = 1; 
			global.response.status = -1;

			while(global.response.status!=100){
				scope( scope_cancellaCarrello )
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
						cancellaCarrello@ShopPort1(request)(global.response)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						cancellaCarrello@ShopPort2(request)(global.response)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						cancellaCarrello@ShopPort3(request)(global.response)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						cancellaCarrello@ShopPort4(request)(global.response)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						cancellaCarrello@ShopPort5(request)(global.response)
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
			println@Console("Si desidera effettuare un altra operazione?(Digitare il numero dell'operazione)")()
 		}
 		/*
 		Richiedo l'acquisto di un carrello
 		*/
 		else if(operazione == 4){
 			println@Console("\nDigitare il nome del carrello che si vuole acquistare:")();
 			in(acquista.nome);

 			global.currentSending = 1; 
			global.risposta.status = -1;

			while(global.risposta.status!=100){
				scope( scope_acquistaCarrello )
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
					println@Console("currentSending: "+global.currentSending+"    status: "+global.risposta.status )();
					sleep@Time(1000)();
					if(global.currentSending == 1){
						println@Console( "Invio a SERVER 1" )();
						acquistaCarrello@ShopPort1(acquista)(global.risposta)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						acquistaCarrello@ShopPort2(acquista)(global.risposta)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						acquistaCarrello@ShopPort3(acquista)(global.risposta)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						acquistaCarrello@ShopPort4(acquista)(global.risposta)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						acquistaCarrello@ShopPort5(acquista)(global.risposta)
					};
					if( global.risposta.status == 0 ) {
						global.currentSending++
						//global.risposta.status = global.currentSending
					}else{
						global.currentSending = global.risposta.status
					};

					println@Console( global.risposta.message )()
				}
			};
 			//acquistaCarrello@ShopPort1(acquista)(risposta);
 			//println@Console(risposta.message)();
			println@Console("Si desidera effettuare un altra operazione?(Digitare il numero dell'operazione)")()
 		}
 		/*
 		Richiedo l'aggiunta di elementi all'interno del carrello.
 		*/
 		else if(operazione == 5){
 			println@Console("\nDigitare il nome del carrello: ")();
 			in(aggiunta.nomeCarrello);
 			println@Console("Digitare il nome del prodotto da aggiungere: ")();
 			in(aggiunta.nomeProdotto);
 			println@Console("Digitare la quantita' di prodotto che si vuole aggiungere: ")();
 			in(quantitaDaAggiungere);
 			aggiunta.numeroQuantita = int(quantitaDaAggiungere);

 			global.currentSending = 1; 
			global.response.status = -1;
			while(global.response.status!=100){
				scope( scope_aggiungiElementi )
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
						aggiungiElementi@ShopPort1(aggiunta)(global.response)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						aggiungiElementi@ShopPort2(aggiunta)(global.response)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						aggiungiElementi@ShopPort3(aggiunta)(global.response)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						aggiungiElementi@ShopPort4(aggiunta)(global.response)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						aggiungiElementi@ShopPort5(aggiunta)(global.response)
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
 			//aggiungiElementi@ShopPort1(aggiunta)(response);
 			//println@Console(response.message)();
			println@Console("Si desidera effettuare un altra operazione?(Digitare il numero dell'operazione)")()
 		}
 		/*
 		Richiedo la rimozione di elementi all'interno del carrello.
 		*/
		else if(operazione == 6){
			println@Console("\nDigitare il nome del carrello: ")();
 			in(eliminazione.nomeCarrello);
 			println@Console("Digitare il nome del prodotto da eliminare: ")();
 			in(eliminazione.nomeProdotto);
 			println@Console("Digitare la quantita' di prodotto che si vuole eliminare: ")();
 			in(quantitaDaEliminare);
 			eliminazione.numeroQuantita = int(quantitaDaEliminare);


 			global.currentSending = 1; 
			global.response.status = -1;

			while(global.response.status!=100){
				scope( scope_rimuoviElementi )
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
						rimuoviElementi@ShopPort1(eliminazione)(global.response)
					} else if( global.currentSending == 2 ) {
						println@Console( "Invio a SERVER 2" )();
						rimuoviElementi@ShopPort2(eliminazione)(global.response)
					} else if( global.currentSending == 3 ) {
						println@Console( "Invio a SERVER 3" )();
						rimuoviElementi@ShopPort3(eliminazione)(global.response)
					} else if( global.currentSending == 4 ) {
						println@Console( "Invio a SERVER 4" )();
						rimuoviElementi@ShopPort4(eliminazione)(global.response)
					} else if( global.currentSending == 5 ) {
						println@Console( "Invio a SERVER 5" )();
						rimuoviElementi@ShopPort5(eliminazione)(global.response)
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

 			//rimuoviElementi@ShopPort1(eliminazione)(response);
 			//println@Console(response.message)();
			println@Console("Si desidera effettuare un altra operazione?(Digitare il numero dell'operazione)")()
		}

		else if (operazione == 7){
			keepRunning = false
		}

		else{
			println@Console("ERRORE: Operazione non disponibile.")()
		}
	}



}
