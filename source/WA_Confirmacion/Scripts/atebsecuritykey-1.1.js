function Sign(KeyHex, PassCode, Message) {
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(KeyHex, 'ENCRYPTED PRIVATE KEY');
    var rsa = KEYUTIL.getKey(CertPEM, PassCode);
    var sig = new KJUR.crypto.Signature({ "alg": "SHA1withRSA" });
    sig.init(rsa);
    var hSignVal = sig.signString(Message);
    return hSignVal;
    
}

function VerifySign(CertHex, Message, SignatureHex) {
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(CertHex, 'CERTIFICATE');
    var PubKey = KEYUTIL.getKey(CertPEM);
    var sig = new KJUR.crypto.Signature({ "alg": "SHA1withRSA" });
    sig.init(PubKey);
    sig.updateString(Message);
    var isValid = sig.verify(SignatureHex);
}

function getRFC(CertHex)
{
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(CertHex, 'CERTIFICATE');
    var x509 = new X509();
    x509.readCertPEM(CertPEM);
    var OsubjHex = x509.getSubjectHex();
    var StrSubj = ConvertFromHex(OsubjHex);
    var rfcpos = StrSubj.search(/[A-Z&Ñ]{3,4}[0-9]{2}(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]/);
    if (rfcpos == -1) {
        rfcpos = "- Error RFC -";
    } else {
        rfcpos = StrSubj.substring(rfcpos, rfcpos + 13);
    }
    return rfcpos;
}

function getSerialNumber(CertHex)
{
    var x = new X509();
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(CertHex, 'CERTIFICATE');
    x.readCertPEM(CertPEM);
    var nshex = x.getSerialNumberHex();
    return ConvertFromHexToString(nshex);
}

function getNotAfter(CertHex)
{
    var x = new X509();
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(CertHex, 'CERTIFICATE');
    x.readCertPEM(CertPEM);
    var NotAfter = x.getNotAfter();
    return NotAfter;
}
function getNotBefore(CertHex) {
    var x = new X509();
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(CertHex, 'CERTIFICATE');
    x.readCertPEM(CertPEM);
    var NotBefore = x.getNotBefore();
    return NotBefore;
}
function getCertificateInfo(CertHex)
{
    var x = new X509();
    var CertPEM = KJUR.asn1.ASN1Util.getPEMStringFromHex(CertHex, 'CERTIFICATE');
    x.readCertPEM(CertPEM);
    var StrInfo = x.getInfo();
    return StrInfo;
}

function Uint8ArrrayToStringHex(array){
    var e = array.byteLength;
    var hex = "";
    for (i = 0; i < e; i++)
        hex += byte2Hex(array[i]);

    return hex;
}

function ConvertFromStringToHex(inputHex){
    inputHex = inputHex.Replace("-", "");

    var resultantArray = new byte[inputHex.Length / 2];
    for (i = 0; i < resultantArray.Length; i++)
        resultantArray[i] = Convert.ToByte(inputHex.Substring(i * 2, 2), 16);

    return resultantArray;
}

function ConvertFromHexToString(hex) {
    var str = '';
    for (var i = 0; i < hex.length; i += 2) {
        var v = parseInt(hex.substr(i, 2), 16);
        if (v) str += String.fromCharCode(v);
    }
    return str;
}

function ConvertFromHex(hex) {
    var hex = hex.toString();//force conversion
    var str = '';
    for (var i = 0; i < hex.length; i += 2)
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    return str;
}