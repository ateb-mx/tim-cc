<%@ Page Title="" Language="C#" MasterPageFile="~/Content.Master" AutoEventWireup="true" CodeBehind="Confirmacion.aspx.cs" Inherits="WA_Confirmacion.Confirmacion" %>
<asp:Content ID="Content1" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <script src="Scripts/Noti.js"></script>
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
            

            var captcha =  grecaptcha.getResponse();
            
            if (captcha.length !=0) {
              
                try {
                    
                    SignResult = Sign(Key,pass, COriginal);
                    Noti('Firma Generada Correctamente','info');
                }
                catch (err) {
                    //alert(err);
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
                        //alert(err);
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
    <script type="text/javascript">
       
    </script>
    <div class="panel panel-default" >
        <div class="panel-heading">Solicitud Clave Confirmación
            <div style="float:right">
                <a href="#modalHelp" role="button" data-toggle="modal"><img id="imgHelp" src="Images/5-Infos.png" height="20" alt="Ayuda" title="Ayuda"/></a>
            </div>
        </div>
        <div class="panel-body">
            <div class="col-xs-6">
                <div class="form-group">
                    <label for="CertFile" class="control-label">Certificado (archivo .cer)</label>
                    <input id="CertFile" type="file" tabindex="2" class="file" data-show-preview="false" data-show-upload="false" data-show-remove="false" data-allowed-file-extensions='["cer"]' data-language="es" onchange="openFile(event,$(this),'cer')" required="required"/>
                    <input id="HexCert" name="hexCert" type="text" hidden="hidden" />
                </div>
            </div>
            <div class="col-xs-6">
                <div class="form-group">
                    <label for="txtrfc" class="control-label">RFC Certificado</label>
                    <input id="txtrfc" class="form-control" type="text" placeholder="RFC" disabled="disabled" />
                </div>
            </div>  
            <div class="col-xs-6">
                <div class="form-group">
                    <label for="KeyFile" class="control-label">Llave Privada (archivo .key)</label>
                    <input id="KeyFile" type="file" tabindex="3" class="file" data-show-preview="false" data-show-upload="false" data-show-remove="false" data-allowed-file-extensions='["key"]' data-language="es" onchange="openFile(event,$(this),'key')" required="required"/>
                    <input id="HexKey" name="hexKey" type="text" hidden="hidden"  />
                </div>
            </div>
            <div class="col-xs-6">
                <div class="form-group" id="password-form-group">
                    <label for="passw" class="control-label">Contraseña de Llave Privada</label>
                    <input id="PassCert" type="password" tabindex="4" class="form-control" placeholder="Contraseña Llave Privada .key" required="required" />
                </div>
            </div>

            <div class="col-xs-6">
                <div class="form-group">
                    <label for="NumberOperation" class="control-label">Número de Claves</label>
                    <select class="form-control" id="NumberOperation" title="Total de Códigos" tabindex="5" required="required" >
                        <option value="1">1</option>
                        <option value="2">2</option>
                        <option value="3">3</option>
                        <option value="4">4</option>
                        <option value="5">5</option>
                    </select>
                </div>
            </div>
            <div class="col-xs-6">
                <div class="form-group">
                    <label for="Email" class="control-label">Correo electrónico de contacto</label>
                    <input id="Email" type="email" tabindex="1" class="form-control" placeholder="Correo Electrónico"  required="required" />
                </div>
            </div>
            <div class="col-xs-6">
                <div class="form-group">
                    <img src="Images/ATEB-01a.png" width="120" />
                    <label for="txtFecha" class="hidden">Fecha</label>
                    <input id="txtFecha" type="text" class=" hidden" disabled="disabled"/>
                </div>
            </div>
            <div class="col-xs-6">
                <div class="g-recaptcha" style="float:left" data-sitekey="6Lf9lRYUAAAAAPUONS0UO0q2QL7uWg9Uk0pQ8PFL"></div>
            </div>
            <div class="col-xs-6" style="text-align:right; vertical-align:text-bottom;">
                <div class="form-group">
                    <button name="submit" type="submit" id="contact-submit" data-submit="...Sending" onclick="Verify($('#PassCert').val())" class="btn btn-default bottom">Generar Claves</button>
                </div>
            </div>
            <div class="col-xs-2"></div>
            <div class="col-xs-12">
                <div class="form-group">
                    <div id="notifications"></div>
                </div>
            </div>  
	    </div>
    </div>
    <div class="modal fade" id="modalCC" tabindex="-1" role="dialog" data-backdrop="static">
	    <div class="modal-dialog modal-lg" role="document">
		    <div class="modal-content">
			    <div class="modal-header">
				    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                    <h4 class="modal-title">Claves Generadas</h4>
			    </div>
			    <div class="modal-body">
                    <asp:TextBox ID="Result" TextMode="MultiLine" Height="90px" runat="server" ReadOnly="true" CssClass="form-control" ></asp:TextBox>
                </div>
            </div>
        </div>
    </div>
    <div class="modal fade" id="modalHelp" tabindex="-1" role="dialog" data-backdrop="static">
	    <div class="modal-dialog modal-lg" role="document">
		    <div class="modal-content">
			    <div class="modal-header">
				    <button id="closeVideo" type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                    <h4 class="modal-title">Ayuda Solicitud de Clave de Confirmación</h4>
			    </div>
			    <div class="modal-body">
                    <iframe id="ifrVideo" width="854" height="480" src="" frameborder="0" allowfullscreen></iframe>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
