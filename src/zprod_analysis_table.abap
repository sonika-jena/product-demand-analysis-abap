@EndUserText.label : 'Product Analysis Table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zprod_analysis {

  key client : abap.clnt not null;
  key id     : abap.int4 not null;
  name       : abap.char(30);
  category   : abap.char(20);
  subcat     : abap.char(20);
  sales      : abap.int4;
  stock      : abap.int4;

}