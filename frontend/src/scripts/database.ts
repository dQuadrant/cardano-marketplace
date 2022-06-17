export function openDB():Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
        try {

            let request :IDBOpenDBRequest = window.indexedDB.open("marketDB", 2);

            request.onerror = e => {
                console.log('Error opening db', e);
                reject('Error');
            };

            request.onsuccess = (e:any ) => {
                console.log("Success opening db",e)
                resolve(e.target.result);
            };

            request.onupgradeneeded = (event: any) => {
                console.log("Upgrading db",event)
                var db: IDBDatabase = event.target.result;
                var objectStore = db.createObjectStore("utxoContent", { keyPath: "utxo" });
                objectStore.createIndex("utxo", "utxo", { unique: true });
                objectStore.transaction.oncomplete = event => {
                    Promise.resolve(db)
                }
            };
        } catch (e) {
            reject(e.message)
        }
    });
}
export function saveUtxos(db: IDBDatabase| undefined|null ,objects:Array<any>): Promise<any>{
    if(!db){
        return Promise.reject("Null db instance")
    }
    return new Promise((resolve, reject):void => {
        let trans: IDBTransaction = db.transaction('utxoContent', 'readwrite');
        trans.oncomplete = () => {
            resolve(objects);
        };
        trans.onerror=(e)=>{
            console.log("Saving error",e)
            reject("Error")
        }

        let store = trans.objectStore('utxoContent');
        objects.forEach(x =>{
            store.put(x);
        })
        trans.commit()
    })
}
export function getReadHandle(db:IDBDatabase): IDBObjectStore{
    const trans=db.transaction('utxoContent');
    return trans.objectStore('utxoContent')

}
export function getUtxo(handle: IDBObjectStore,id) {
    if(!handle){
        return Promise.reject(" Null Object store handle")
    }
    return new Promise((resolve, reject) => {

        var request = handle.get(id);
        request.onerror = event => {
            reject(event)
        };
        request.onsuccess = event => {
            // Do something with the request.result!
            console.log("returning from db",request.result)
            if(request.result)
                resolve(request.result)
            else
                reject("Not found")
        }
    })
}
