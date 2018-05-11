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
type typeRisposta: void{
	.message: string
	.status?: int
}
type typeVediListaShop: void{
	.message: string
	.listaShop?: typelistaOggetti
	.status?: int
}
type typeAggiungiProdotto: void{
	.nomeCarrello: string
	.nomeProdotto: string
	.numeroQuantita: int
}

interface ClientInterface {
  RequestResponse:  creaCarrello(typeCarrello)(typeRisposta),
  				    vediListaOggetti(int)(typeVediListaShop),
  				    cancellaCarrello(typeCarrello)(typeRisposta),
  				    acquistaCarrello(typeCarrello)(typeRisposta),
  				    aggiungiElementi(typeAggiungiProdotto)(typeRisposta),
					rimuoviElementi(typeAggiungiProdotto)(typeRisposta),
					
					//Non richiesti dalle specifiche
					vediElementiCarrello(typeRichiesta)(typeCarrello),
					vediCarrelliDisponibili(int)(typeRisposta),
					STAMPATUTTO(void)(void)
}
