/*
type typeReplay: void{
  .message: string
}
*/
type typelistaCarrelli: void{
	.carrello*: typeCarrello
}
type typeCarrello: void{
	.nome: string
	.lista?: typelistaOggetti
}
type typelistaOggetti: void{
	.oggetto*: typeOggetto
}
type typeOggetto: void{
	.nome: string
	.quantita: int
}
type typeRichiesta: void{
	.message: string
}

/*
Macro-variabile che che contiene le variabili globali del sistema 
e che viene inviata dal server leader al Network Visualizer
*/
type typeStatoGlobale: void{
	.merciNet[0,*]: typelistaOggetti
	.carrelliNet?: typelistaCarrelli
	.carrelliArchiviatiNet?: typelistaCarrelli
	.status?: int
	.message?: string
}

interface NetworkVisualizerInterface {
  RequestResponse:
  				riceviListe(int)(typeStatoGlobale)

}
