using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml;

namespace WA_Confirmacion
{
    public partial class Confirmacion : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {


            if (IsPostBack)
            {
               

                if (this.Request["__EVENTTARGET"].ToString() == "veryCert")
                {
                    Result.Text = "";
                    String[] argsVeryCert = this.Request["__EVENTARGUMENT"].Split('|');

                    if (argsVeryCert[0] == "0")
                    {
                        Mensaje("danger", argsVeryCert[1].ToString());
                    }
                    else
                    {

                        String Fecha = argsVeryCert[1].ToString();
                        String RFC = argsVeryCert[2].ToString();
                        String NoCertificado = argsVeryCert[3].ToString();
                        String Cantidad = argsVeryCert[4].ToString();
                        String CertBase64 = Convert.ToBase64String(ConvertFromStringToHex(argsVeryCert[5].ToString()));
                        String Firma = Convert.ToBase64String(ConvertFromStringToHex(argsVeryCert[6].ToString()));
                        String email = argsVeryCert[7].ToString();

                        XmlDocument xmldoc = new XmlDocument();
                        xmldoc.Load(Server.MapPath(@"~\Contract\Contract.xml"));

                        XmlNode node = xmldoc.SelectSingleNode("/Confirmacion/Solicitud");

                        if (node != null)
                        {
                            node.Attributes["Fecha"].Value = Fecha;
                            node.Attributes["RFC"].Value = RFC;
                            node.Attributes["NoCertificado"].Value = NoCertificado;
                            node.Attributes["Cantidad"].Value = Cantidad;
                            node.Attributes["Certificado"].Value = CertBase64;
                            node.Attributes["Firma"].Value = Firma;

                            try
                            {
                                WS_Confirmacion.CFDICodigoConfirmacionSoapClient sp = new WS_Confirmacion.CFDICodigoConfirmacionSoapClient();
                                WS_Confirmacion.AuthenticationHeader auth = new WS_Confirmacion.AuthenticationHeader();
                                WS_Confirmacion.ConfirmResult cr = new WS_Confirmacion.ConfirmResult();


                                auth.FechaHoraPeticion = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:sszzz");


                                cr = sp.Confirmar(auth, Encoding.UTF8.GetBytes(xmldoc.OuterXml));

                                if (cr.Estatus == "OK")
                                {
                                    List<String> SCodigos = new List<String>();
                                    StringBuilder sb = new StringBuilder();
                                    foreach (String code in cr.Codes)
                                    {
                                        sb.AppendLine(code);
                                        SCodigos.Add(code);

                                    }
                                    
                                    Result.Text = sb.ToString();
                                    OpenResult();
                                    if (IsValidEmail(email))
                                    {
                                        EnviarMail(SCodigos, email);
                                        Mensaje("success", "Información Generada Correctamente !");
                                    }
                                    else
                                    {
                                        Mensaje("warning", "Información Generada Correctamente, pero es imposible enviar los códigos a su email , ya que no es un email válido !");
                                    }

                                }
                                else
                                {
                                    Mensaje("danger", String.Format("No se puede generar codigos de confirmación: Motivo - {0}:{1}", cr.Error, cr.Mensage));
                                }
                            }
                            catch (Exception ex)
                            {
                                Mensaje("danger", ex.Message);
                            }
                        }

                    }
                }
                
                    
            }
            else
                this.ClientScript.GetPostBackEventReference(this, "arg");

        }
        private void OpenResult()
        {
            ScriptManager.RegisterStartupScript(this, this.GetType(), "OpenResult", "<script>$('#modalCC').modal('show');</script>", false);
        }

        private void Mensaje(String NotiType, String Msg)
        {
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Noti", "Noti('" + Msg + "','" + NotiType + "');", true);
        }
        protected bool IsValidEmail(String emailaddress)
        {
            try
            {
                var addr = new System.Net.Mail.MailAddress(emailaddress);
                return addr.Address == emailaddress;
            }
            catch
            {
                return false;
            }
        }

        protected void EnviarMail(List<String> Mails, String Receptor)
        {
            Mail m = new Mail();
            m.EnviarMail(Mails, Receptor, System.Net.Mail.MailPriority.Normal);
        }

        protected byte[] ConvertFromStringToHex(string inputHex)
        {
            inputHex = inputHex.Replace("-", "");

            byte[] resultantArray = new byte[inputHex.Length / 2];
            for (int i = 0; i < resultantArray.Length; i++)
            {
                resultantArray[i] = Convert.ToByte(inputHex.Substring(i * 2, 2), 16);
            }
            return resultantArray;
        }
    }
}