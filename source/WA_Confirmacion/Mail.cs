using NLog;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Net.Mime;
using System.Text;
using System.Web;

namespace WA_Confirmacion
{
    public class Mail : IDisposable
    {
        private Logger log = LogManager.GetCurrentClassLogger();

        public void Dispose()
        {
            GC.Collect();
        }

        public void EnviarMail(List<String> Mensajes, String MailReceptor, MailPriority prioridad)
        {
            String ImagePath = Path.Combine(System.Web.Hosting.HostingEnvironment.ApplicationPhysicalPath, "Images");

            System.Net.Mail.MailMessage DPIVAMail = new System.Net.Mail.MailMessage();
            DPIVAMail.To.Add(MailReceptor);
            DPIVAMail.Subject = Properties.Settings.Default.Asunto + " " + DateTime.Now.ToString().Replace("/", "_");
            DPIVAMail.SubjectEncoding = System.Text.Encoding.UTF8;
            DPIVAMail.Priority = prioridad;
            //Copia para 
            if (!String.IsNullOrEmpty(Properties.Settings.Default.MailCopia))
            {
                String[] Copias = Properties.Settings.Default.MailCopia.Split(',');
                foreach (String Copia in Copias)
                {
                    if (!String.IsNullOrEmpty(Copia))
                    {
                        DPIVAMail.Bcc.Add(Copia);
                    }
                }
            }

            int IntentosMail = 0;
            StringBuilder bd = new StringBuilder();

            //FORMATO HTML
            bd.Append("<body>");
            //Colocar Logo de ATEB
            bd.Append("<img src='cid:logo_ateb' width=80 height=80 />");
            bd.Append("<h1><blockquote>ATEB Servicios S.A de C.V</blockquote></h1>");
            bd.Append("<h1><blockquote><blockquote>Aviso Automático</blockquote></blockquote> </h1>");
            if (prioridad != MailPriority.High)
            {
                bd.Append("<p>En el presente se le informa que ha generado los siguientes <strong>Códigos de Confirmación</strong> </p>");
            }
            bd.Append("<p>Codigos de Confirmación</p>");
            bd.Append("<p>Detalle: </p>");
            bd.Append("<ul>");
            foreach (String msj in Mensajes)
            {
                if (msj != "")
                {
                    if (prioridad != MailPriority.High)
                        bd.Append("<blockquote><strong><li>" + msj + "</li></strong></blockquote>");
                    else if (prioridad == MailPriority.High)
                        bd.Append("<blockquote><strong><font color=\"red\"><li>" + msj + "</li></font></strong></blockquote>");
                }
                else
                    bd.Append("<br>");
            }

            bd.Append("</ul>");
            bd.Append("<p>Fecha : <strong>" + DateTime.Now + "</strong></p>");
            bd.Append("<p>Fecha : <strong>NOTA:</strong> Los códigos generados tienen una vigencia de 24hrs desde su generación.</p>");
            bd.Append("<p>&nbsp;</p>");
            bd.Append("<h3>Contáctanos : <strong>Soporte Técnico</strong></h3>");
            bd.Append("<p><strong>Online: &nbsp; <a href=http://www.ateb.mx/soporte/> CONTACTANOS</a></strong></p>");
            bd.Append("<h3>Ingresa al Portal: &nbsp; <a href=http://www.ateb.mx/> www.ateb.mx</a></h3>");
            bd.Append("<hr />");
            bd.Append("<p style='font-style: italic;'><samp><code><kbd>Este es un Aviso generado automaticamente,</kbd></code></samp><samp><code><kbd> favor de no responder el siguiente mail, ya que es de manera informativa.</kbd></code></samp></p>");
            bd.Append("<pre data-fulltext='' data-placeholder='Traducción' dir='ltr' id='tw-target-text'>");
            bd.Append("This information is generated automatically so please do not reply to this mail .</pre>");
            bd.Append("</body>");

            AlternateView html = AlternateView.CreateAlternateViewFromString(bd.ToString(), Encoding.UTF8, MediaTypeNames.Text.Html);
            LinkedResource ImgLogo = new LinkedResource(Path.Combine(ImagePath, "ateb_r.png"), MediaTypeNames.Image.Jpeg);
            ImgLogo.ContentId = "logo_ateb";
            html.LinkedResources.Add(ImgLogo);
            DPIVAMail.AlternateViews.Add(html);

            //LCOMail.Body = bd.ToString();
            //LCOMail.IsBodyHtml = true;

            //LCOMail.BodyEncoding = System.Text.Encoding.UTF8;
            DPIVAMail.From = new System.Net.Mail.MailAddress(Properties.Settings.Default.MailEmisor, Properties.Settings.Default.MailEmisorDesc);
            System.Net.Mail.SmtpClient Server = new System.Net.Mail.SmtpClient();
            Server.Credentials = new System.Net.NetworkCredential(Properties.Settings.Default.MailUser, Properties.Settings.Default.MailPass);
            //Server.EnableSsl = true;
            Server.Host = Properties.Settings.Default.Host;
            Server.Port = Properties.Settings.Default.Puerto;

            while (IntentosMail != Properties.Settings.Default.IntentosMail)
                try
                {
                    Server.Send(DPIVAMail);
                    IntentosMail = Properties.Settings.Default.IntentosMail;
                }
                catch (System.Net.Mail.SmtpException ex)
                {
                    log.Error(String.Format("Error al Envio de Mail Intento ( {0} ): " + ex.Message, IntentosMail));
                    Console.WriteLine(String.Format("Error al Envio de Mail Intento ( {0} ): " + ex.Message, IntentosMail));

                    if (IntentosMail == Properties.Settings.Default.IntentosMail)
                    {
                        log.Error("Error al Envio de Mail  " + ex.Message);
                        throw new ApplicationException("Error de envio de mail ", ex);
                    }
                    IntentosMail++;
                }

        }
    }
}