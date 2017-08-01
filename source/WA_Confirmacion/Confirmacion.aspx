<%@ Page Title="" Language="C#" MasterPageFile="~/Content.Master" AutoEventWireup="true" CodeBehind="Confirmacion.aspx.cs" Inherits="WA_Confirmacion.Confirmacion" %>
<asp:Content ID="Content1" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <script src="Scripts/jquery.min.js"></script>
    <script src="Scripts/Notify.js"></script>
    <script src="Scripts/Noti.js"></script>
    <script src="https://www.google.com/recaptcha/api.js"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            $('#Year').html(new Date().getFullYear());
            $('#txtFecha').val(getDateTimeFormat());
        });
        //OBTIENE LA FECHA ACTUAL EN FORMATO ESPECIFICO
        function getDateTimeFormat() {
            var now = new Date();
            var now_utc = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds()).toISOString();
            var now_offset = now.getTimezoneOffset() / 60;
            var now_utc_format = now_utc.substring(0, (now_utc.length - 5));
            if (now_offset > 0) {

                if (now_offset.toString().length == 1)
                    now_utc_format = now_utc_format + '-' + '0' + now_offset + ':00';
                else
                    now_utc_format = now_utc_format + '-' + now_offset + ':00';
            }
            else {
                if (now_offset.toString().length == 1)
                    now_utc_format = now_utc_format + '+' + '0' + now_offset + ':00';
                else
                    now_utc_format = now_utc_format + '+' + now_offset + ':00';
            }
            return now_utc_format;
        }
    </script>
    <script type="text/javascript">
        //FUNCION QUE OBTIENEN EL ARCHIVO ESPECIFICADO
        var openFile = function (event, control,ftype) {
            var input = event.target;
            var fr = new FileReader();
            fr.onloadend = function () {
                var u = new Uint8Array(this.result);
                var ControlType = control.val().split('.')[1];
                switch (ftype) {
                    case 'key':

                        if (ControlType == 'key')
                            $('#HexKey').val(Uint8ArrrayToStringHex(u));
                        else if (ControlType == 'cer') {
                            $(control).val('');
                            Noti('No es un archivo (.key)', 'warning');
                        }
                        else {
                            $(control).val('');
                            Noti('No es un archivo permitido', 'warning');
                        }

                        break;
                    case 'cer':

                        if (ControlType == 'cer') {
                            $('#HexCert').val(Uint8ArrrayToStringHex(u));
                            $('#txtrfc').val(getRFC($('#HexCert').val()) + '-' + getSerialNumber($('#HexCert').val()));
                        }
                        else if (ControlType == 'key') {
                            $('#txtrfc').val('');
                            $(control).val('');
                            Noti('No es un archivo (.cer)', 'warning');
                        }
                        else {
                            $('#txtrfc').val('');
                            $(control).val('');
                            Noti('No es un archivo permitido', 'warning');
                        }
                        break;
                }
            };
            fr.readAsArrayBuffer(input.files[0]);
        };
        //FUNCION QUE VERIFICA LA FIRMA DEL CERTIFICADO ESPECIFICO
        function Verify(pass) {
            <%Session["Confirma"] = true; %>
            $('#Result').val('');
            var resp = '';
            var SignResult = '';
            
            
            var Cert = $('#HexCert').val();
            var Key = $('#HexKey').val();
            var email = $('#Email').val();

            //ELEMENTOS DE LA CADENA ORIGINAL
            var Fecha = getDateTimeFormat();
            var RFC = getRFC($("#HexCert").val());
            var NoCertificado = getSerialNumber($("#HexCert").val());
            //var Cantidad = document.getElementById('NumberOperation').options[document.getElementById('NumberOperation').selectedIndex].value;
            var Cantidad = $('#NumberOperation').val();
            var COriginal = "||" + Fecha + "|" + RFC + "|" + NoCertificado + "|" + Cantidad + "||";
            

            captcha = grecaptcha.getResponse();
            
            if (!captcha) {
              
                try {
                    
                    SignResult = Sign(Key,pass, COriginal);
                    Noti('Firma Generada Correctamente','info');
                }
                catch (err) {
                    alert(err);
                    resp = '0|El archivo de la llave privada no es válido o la contraseña es incorrecta.';
                }

                if (resp == '') {
                    try {
                        var isValid = VerifySign(Cert, COriginal, SignResult);
                            Noti('Verificación de Firma Correcta','info');
                        if (isValid === false) {
                            resp = '0|El certificado no fue derivado de la llave privada.';
                        }
                        else {
                            resp = '1' + '|' + Fecha + '|' + RFC + "|" + NoCertificado + '|' + Cantidad + '|' + document.getElementById("HexCert").value + '|' + SignResult + '|' + email;
                        }
                    }
                    catch (err) {
                        alert(err);
                        resp = '0|El archivo del Certificado no es válido.';
                    }
                }

                __doPostBack('veryCert', resp);
            }
            else {
                Noti('Petición no válida !','warning');
            }
            return;
       }
    </script>
       <div class="row">
               <div class="col-md-3"></div>
               <div class="col-md-6">
                           <div class="panel panel-default">
                               <div class="panel-heading"></div>
                               <div class="panel-body">
                                       <table class="table tab-content">
                                           <tr>
                                               <td>
                                                   <h1>Código de Confirmación</h1>
                                                   <h2>Solicitud Digital</h2>
                                                   <fieldset>
                                                       <input id="txtFecha" type="text"  disabled="disabled"/>
                                                        <h4>Archivo de certificado público (*.cer)</h4>
                                                        <input  placeholder="Certificado de Sello Digital" type="file" tabindex="1" required="required" onchange="openFile(event,$(this),'cer')" />
                                                        <input id="HexCert" name="hexCert" type="text" hidden="hidden" />
                                                        <input id="txtrfc" type="text" placeholder="RFC" disabled="disabled" />
                                                    </fieldset>
                                                   <fieldset>
                                                        <h4>Archivo de llave privada (*.key)</h4>
                                                        <input placeholder="Llave Privada" type="file" tabindex="2" required="required" onchange="openFile(event,$(this),'key')" />
                                                        <input id="HexKey" name="hexKey" type="text" hidden="hidden"  />
                                                    </fieldset>
                                                   <fieldset>
                                                        <h4>Contraseña de llave privada</h4>
                                                        <input placeholder="Contraseña" id="PassCert" type="password" tabindex="3" required="required" />
                                                        
                                                    </fieldset>
                                                   <fieldset>
                                                        <h4>Correo electrónico de contacto</h4>
                                                        <input  placeholder="Correo Electrónico" id="Email" type="email" tabindex="5" required="required" />
                                                    </fieldset>
                                                   <div class="col-sm-4">
                                                   <fieldset>
                                                        <h4>Número de Códigos</h4>
                                                        <select class="NumbreOperation" id="NumberOperation" title="Total de Códigos" tabindex="4" required="required" >
                                                            <option value="1">1</option>
                                                            <option value="2">2</option>
                                                            <option value="3">3</option>
                                                            <option value="4">4</option>
                                                            <option value="5">5</option>
                                                        </select>
                                                    </fieldset>
                                                       </div>
                                                   <div class="col-sm-4">
                                                   <fieldset>
                                                       <br />
                                                        <div class="g-recaptcha" data-sitekey="6Lf9lRYUAAAAAPUONS0UO0q2QL7uWg9Uk0pQ8PFL"></div>
                                                    </fieldset>
                                                       </div>
                                                   <fieldset>
                                                        <button name="submit" type="submit" id="contact-submit" data-submit="...Sending" onclick="Verify($('#PassCert').val())">Generar</button>
                                                    </fieldset>
                                                    <fieldset>
                                                        <div align="center"><h4>Códigos Generados</h4></div>
                                                        <div align="center"><asp:TextBox ID="Result" TextMode="MultiLine" Height="90px" Width="300px" runat="server" ></asp:TextBox></div>
                                                    </fieldset>
                                                    <p></p>
                                                    <fieldset>
                                                        <div id="notifications"></div>
                                                    </fieldset>
                                                   <p id="Copy" class="copyright"><a id="LinkAteb" href="https://www.ateb.com.mx" target="_blank" title="Ateb Servicios">ATEB Servicios S.A de C.V.</a>   copyright© <label id="Year"></label></p>
                                               </td>
                                           </tr>
                                       </table>
                               </div>
                           </div>
                   </div>
               <div class=" col-md-2"></div>
           </div>

</asp:Content>
