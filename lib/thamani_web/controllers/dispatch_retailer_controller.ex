defmodule ThamaniWeb.DispatchRetailerController do
  use ThamaniWeb, :controller
  require Ecto.Query
  require Ecto
  use Ecto.Schema
  alias Thamani.Dispatches
  alias Thamani.Dispatches_Retailer
  alias Thamani.Dispatches_Retailer.Dispatch_Retailer
  alias Thamani.Batches
  alias Thamani.Inventories
  alias Thamani.Retail_Returns
  alias Thamani.Manufacturer_orders
  alias Thamani.Retman_orders
  alias Thamani.Returns
  alias Thamani.Repo

  plug(:put_layout, "manufacturer.html")
  plug(:scrub_params, "dispatch__retailer" when action in [:create, :update])

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, current_user) do
    user = current_user
    count_stock = Inventories.get_count_restock_man(current_user)
    count_order = Manufacturer_orders.get_count_order(current_user)
    count_order_retman = Retman_orders.get_count_order(current_user)
    count_return = Returns.get_count_recieved(current_user)
    count_return_retail = Retail_Returns.get_count_recieved(current_user)

    dispatch =
      user
      |> user_dispatch
      |> Repo.all()
      |> Repo.preload(:company)
      |> Repo.preload(:sku)

    if dispatch do
      render(
        conn,
        "index.html",
        dispatch: dispatch,
        user: user,
        count_stock: count_stock,
        count_order: count_order,
        count_order_retman: count_order_retman,
        count_return: count_return,
        count_return_retail: count_return_retail
      )
    else
      conn
      |> put_flash(:error, "Not authorised to access that page")
      |> redirect(to: dispatch_retailer_path(conn, :index))
    end
  end

  def new(conn, params, current_user) do
    bat = Dispatches_Retailer.get_items_datalist(current_user)
    count_stock = Inventories.get_count_restock_man(current_user)
    count_order = Manufacturer_orders.get_count_order(current_user)
    count_order_retman = Retman_orders.get_count_order(current_user)
    count_return = Returns.get_count_recieved(current_user)
    count_return_retail = Retail_Returns.get_count_recieved(current_user)

    company = Dispatches_Retailer.get_company()

    changeset =
      current_user
      |> Ecto.build_assoc(:dispatches_retailer)
      |> Dispatch_Retailer.changeset(params)

    render(
      conn,
      "new.html",
      changeset: changeset,
      bat: bat,
      company: company,
      count_stock: count_stock,
      count_order: count_order,
      count_order_retman: count_order_retman,
      count_return: count_return,
      count_return_retail: count_return_retail,
      map: "map",
      item: "",
      retailer: "",
      from_name: "",
      to_name: "",
      quantity: "",
      description: "",
      order: "",
      amount: "",
      eta: "",
      etd: "",
      currency: "",
      distance: "",
      loader_class: " ",
      message_class: " ",
      alert_class: " ",
      long_process_button_text: " "
    )
  end

  def create(
        conn,
        %{
          "dispatch__retailer" => %{
            "retailer" => retailer,
            "transporter" => transporter,
            "transporterid" => transporterid,
            "description" => description,
            "active" => active
          },
          "item" => item,
          "quantity" => quantity,
          "uom" => uom
        },
        current_user
      ) do
    bat = Dispatches_Retailer.get_items_datalist(current_user)

    item_id = Enum.map(item ,fn x -> Batches.get_item_id!(x) end)
    price = Enum.map(item_id ,fn x -> Dispatches_Retailer.get_price(x) end)
    batch = Enum.map(item ,fn x -> Batches.get_batch_alone(x) end)
    expiry = Enum.map(item ,fn x -> to_string(Batches.get_expiry!(x)) end)
    production = Enum.map(item ,fn x -> to_string(Batches.get_production!(x)) end)

    last =
      case Dispatches_Retailer.get_last_id() do
        nil -> "1"
        _ -> Dispatches_Retailer.get_last_id() + 1
      end

    scode = Enum.map(item ,fn x -> Batches.get_batch(x) <> "21" <> to_string(last + 1) end)
    shipping = Enum.map(item ,fn x -> Batches.get_batch_!(x) <> "21" <> to_string(last + 1) end)
    total = Enum.map(price ,fn x -> String.to_float(x) end)
    count_stock = Inventories.get_count_restock_man(current_user)
    count_order = Manufacturer_orders.get_count_order(current_user)
    count_order_retman = Retman_orders.get_count_order(current_user)
    count_return = Returns.get_count_recieved(current_user)
    count_return_retail = Retail_Returns.get_count_recieved(current_user)
    company = Dispatches_Retailer.get_company()

    list_item =
      item_id
      |> Enum.chunk_every(1)
      |> Enum.map(fn [a] -> %{"item" => a} end)

    list_quantity =
        quantity
        |> Enum.chunk_every(1)
        |> Enum.map(fn [b] -> %{"quantity" => b} end)

    list_batch =
      batch
      |> Enum.chunk_every(1)
      |> Enum.map(fn [c] -> %{"batch" => c} end)

    list_expiry =
        expiry
        |> Enum.chunk_every(1)
        |> Enum.map(fn [d] -> %{"expiry" => d} end)

    list_production =
        production
        |> Enum.chunk_every(1)
        |> Enum.map(fn [e] -> %{"production" => e} end)

    list_scode =
        scode
        |> Enum.chunk_every(1)
        |> Enum.map(fn [f] -> %{"scode" => f} end)

    list_shipping =
        shipping
        |> Enum.chunk_every(1)
        |> Enum.map(fn [g] -> %{"shipping" => g} end)

    list_total =
            total
            |> Enum.chunk_every(1)
            |> Enum.map(fn [h] -> %{"total" => h} end)

    list_uom =
             uom
            |> Enum.chunk_every(1)
            |> Enum.map(fn [i] -> %{"uom" => i} end)

     list =
              Enum.map(
                for {a, b, c, d, e, f, g, h, i} <- Enum.zip([list_item, list_quantity, list_batch, list_expiry, list_production, list_scode, list_shipping, list_total, list_uom]) do
                  Enum.concat([a, b, c, d, e, f, g, h, i])
                end,
                fn x ->
                  Enum.into(x, %{"retailer" => retailer,"transporter" => transporter , "transporterid" => transporterid, "description" => description ,"active" => active, "user_id" => current_user.id})
                end
              )
          changesets =
            Enum.map(list, fn dispatch__retailer ->
              Dispatch_Retailer.changeset(%Dispatch_Retailer{}, dispatch__retailer)
            end)


          result =
            changesets
            |> Enum.with_index()
            |> Enum.reduce(Ecto.Multi.new(), fn {changeset, index}, multi ->
              Ecto.Multi.insert(multi, Integer.to_string(index), changeset)
            end)
            |> Repo.transaction()
   get_timestamp =
        Timex.local()
        |> Timex.format!("{YYYY}{0M}{0D}{h24}")

    qrcode = :qrcode.encode(get_timestamp)
    png = :qrcode_demo.simple_png_encode(qrcode)
    file = :file.write_file("uploads/manufacturer/" <> get_timestamp <> ".png", png)
    # image = Path.expand("./uploads/manufacturer/" <> scode <> ".png")
    logo = Path.expand("./priv/static/images/thamani_logo.png")

    # name = Batches.get_name(item)
    # value = String.to_integer(Enum.join([quantity])) * String.to_integer(price)
    retailer_name = Dispatches_Retailer.get_retailer_name(retailer)
    retailer_owner = Dispatches_Retailer.get_retailer_owner(retailer)
    retailer_email = Dispatches_Retailer.get_retailer_email(retailer)
    html = "<html>
       <head>
       <style>

       .invoice-box {
               max-width: 800px;
               margin: auto;
               padding: 30px;
               border: 1px solid #eee;
               box-shadow: 0 0 10px rgba(0, 0, 0, .15);
               font-size: 16px;
               line-height: 24px;

               color: #555;
           }

           .invoice-box table {
               width: 100%;
               line-height: inherit;
               text-align: left;
           }

           .invoice-box table td {
               padding: 5px;
               vertical-align: top;
           }


           .invoice-box table tr.top table td {
               padding-bottom: 20px;
           }

           .invoice-box table tr.top table td.title {
               font-size: 45px;
               line-height: 45px;
               color: #333;
           }

           .invoice-box table tr.information table td {
               padding-bottom: 40px;
           }

           .invoice-box table tr.heading td {
               background: #eee;
               border-bottom: 1px solid #ddd;
               font-weight: bold;
           }

           .invoice-box table tr.details td {
               padding-bottom: 20px;
           }

           .invoice-box table tr.item td{
               border-bottom: 1px solid #eee;
           }

           .invoice-box table tr.item.last td {
               border-bottom: none;
           }

           .invoice-box table tr.total td:nth-child(5) {
               border-top: 2px solid #eee;
               font-weight: bold;
           }

           @media only screen and (max-width: 600px) {
               .invoice-box table tr.top table td {
                   width: 100%;
                   display: block;
                   text-align: center;
               }

               .invoice-box table tr.information table td {
                   width: 100%;
                   display: block;
                   text-align: center;
               }
           }

           /** RTL **/
           .rtl {
               direction: rtl;

           }

           .rtl table {
               text-align: right;
           }

           .rtl table tr td:nth-child(2) {
               text-align: left;
           }

       </style>
       </head>
       <body>
       <div class='invoice-box'>
        <table cellpadding='0' cellspacing='0'>
        <tr>
            <td colspan='12'>
                <table>
                    <tr>
                        <td class='title' style=''>
                            <img src ='" <> logo <> "' style='width:100%; max-width:250px;'>
                        </td>

                        <td style='text-align:right;font-size:16px'>
                            <h4>Proforma Invoice #: " <> to_string(last + 1) <> "<br></h4>
                            Created: " <> to_string(DateTime.utc_now()) <> "<br>

                        </td>
                    </tr>
                </table>
            </td>
        </tr>

        <tr class=''>
            <td colspan='12'>
                <table>
                    <tr>
                         <td style='text-align:left;font-size:16px'>
                            Thamani Online.<br>
                            info@thamanionline.com<br>
                            Nairobi, Kenya
                        </td>

                        <td style='text-align:right;font-size:16px'>
                        Retailer: " <> retailer_name <> ".<br>
                         " <> retailer_owner <> "<br>
                         " <> retailer_email <> "
                        </td>
                    </tr>
                </table>
            </td>
        </tr>





        <tr class='heading'>
            <td>
                Item
            </td>
            <td>
                Description
            </td>
            <td>
                Qty
            </td>

            <td>
                Price
            </td>
        </tr>



        <tr class='item'>
            <td>

            </td>

            <td>

            </td>
            <td>

            </td>
            <td>

            </td>
        </tr>


        <tr class='total'>
            <td colspan=''>
            <td colspan=''>
            <td colspan='2'>

            <td colspan='2'>
               <strong>Total: </strong>
            </td>
        </tr>
        </table>
 </div>


       </body>
       </html>"
    # file_name = PdfGenerator.generate!(html, page_size: "A4", filename: scode)
    # pdf_file = File.rename(file_name, "uploads/manufacturer/" <> scode <> ".pdf")

    case result do
      {:ok, _} ->
        conn
        |> put_flash(:info, "dispatch created successfully.")
        |> redirect(to: dispatch_retailer_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "new.html",
          changeset: changeset,
          bat: bat,
          company: company,
          count_stock: count_stock,
          count_order: count_order,
          count_order_retman: count_order_retman,
          count_return: count_return,
          count_return_retail: count_return_retail,
          item: "",
          retailer: "",
          from_name: "",
          to_name: "",
          quantity: "",
          description: "",
          order: "",
          amount: "",
          eta: "",
          etd: "",
          currency: "",
          distance: "",
          loader_class: " ",
          message_class: " ",
          alert_class: " ",
          long_process_button_text: " "
        )
    end
  end

  def show(conn, %{"id" => id}, current_user) do
    user = current_user
    count_stock = Inventories.get_count_restock_man(current_user)
    count_order = Manufacturer_orders.get_count_order(current_user)
    count_order_retman = Retman_orders.get_count_order(current_user)
    count_return = Returns.get_count_recieved(current_user)
    count_return_retail = Retail_Returns.get_count_recieved(current_user)
    # bat = Dispatches_Retailer.get_items(current_user)

    dispatch =
      user
      |> user_dispatch_by_id(id)
      |> Repo.preload(:sku)
      |> Repo.preload(:company)

    if dispatch do
      render(
        conn,
        "show.html",
        dispatch: dispatch,
        user: user,
        count_stock: count_stock,
        count_order: count_order,
        count_order_retman: count_order_retman,
        count_return: count_return,
        count_return_retail: count_return_retail
      )
    else
      conn
      |> put_flash(:error, "Not authorised to access that page")
      |> redirect(to: dispatch_retailer_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id}, current_user) do
    dispatch =
      current_user
      |> user_dispatch_by_id(id)

    bat = Dispatches_Retailer.get_items(current_user)
    count_stock = Inventories.get_count_restock_man(current_user)
    count_order = Manufacturer_orders.get_count_order(current_user)
    count_order_retman = Retman_orders.get_count_order(current_user)
    count_return = Returns.get_count_recieved(current_user)
    count_return_retail = Retail_Returns.get_count_recieved(current_user)
    company = Dispatches_Retailer.get_company()

    if dispatch do
      changeset = Dispatch_Retailer.changeset(dispatch, %{})

      render(
        conn,
        "edit.html",
        dispatch: dispatch,
        changeset: changeset,
        bat: bat,
        company: company,
        count_stock: count_stock,
        count_order: count_order,
        count_order_retman: count_order_retman,
        count_return: count_return,
        count_return_retail: count_return_retail
      )
    else
      conn
      |> put_flash(:error, "Not authorised to access that page")
      |> redirect(to: dispatch_retailer_path(conn, :index))
    end
  end

  def update(
        conn,
        %{
          "id" => id,
          "dispatch__retailer" => %{
            "item" => item,
            "quantity" => quantity,
            "retailer" => retailer,
            "transporter" => transporter,
            "transporterid" => transporterid,
            "description" => description
          }
        },
        current_user
      ) do
    scode = Batches.get_batch(item) <> "21" <> id
    item_id = Batches.get_item_id!(item)
    batch = Batches.get_batch_alone(item)
    expiry = Batches.get_expiry!(item)
    production = Batches.get_production!(item)
    price = Dispatches_Retailer.get_price(item_id)
    shipping = Batches.get_batch_!(item) <> " (21) " <> id
    count_stock = Inventories.get_count_restock_man(current_user)
    count_order = Manufacturer_orders.get_count_order(current_user)
    count_order_retman = Retman_orders.get_count_order(current_user)
    count_return = Returns.get_count_recieved(current_user)
    count_return_retail = Retail_Returns.get_count_recieved(current_user)

    dispatch =
      current_user
      |> user_dispatch_by_id(id)

    changeset =
      Dispatch_Retailer.changeset(dispatch, %{
        "item" => item_id,
        "scode" => scode,
        "shipping" => shipping,
        "quantity" => quantity,
        "total" => String.to_integer(Enum.join([quantity])) * Dispatches.to_integer(price),
        "retailer" => retailer,
        "transporter" => transporter,
        "transporterid" => transporterid,
        "description" => description,
        "batch" => batch,
        "expiry" => expiry,
        "production" => production
      })

    bat = Dispatches_Retailer.get_items(current_user)
    company = Dispatches_Retailer.get_company()

    qrcode = :qrcode.encode(scode)
    png = :qrcode_demo.simple_png_encode(qrcode)
    file = :file.write_file("uploads/manufacturer/" <> scode <> ".png", png)
    # image = Path.expand("./uploads/manufacturer/" <> scode <> ".png")
    logo = Path.expand("./priv/static/images/thamani_logo.png")

    name = Batches.get_name(item)
    value = String.to_integer(Enum.join([quantity])) * Dispatches.to_integer(price)
    retailer_name = Dispatches_Retailer.get_retailer_name(retailer)
    retailer_owner = Dispatches_Retailer.get_retailer_owner(retailer)
    retailer_email = Dispatches_Retailer.get_retailer_email(retailer)
    html = "<html>
       <head>
       <style>

       .invoice-box {
               max-width: 800px;
               margin: auto;
               padding: 30px;
               border: 1px solid #eee;
               box-shadow: 0 0 10px rgba(0, 0, 0, .15);
               font-size: 16px;
               line-height: 24px;

               color: #555;
           }

           .invoice-box table {
               width: 100%;
               line-height: inherit;
               text-align: left;
           }

           .invoice-box table td {
               padding: 5px;
               vertical-align: top;
           }


           .invoice-box table tr.top table td {
               padding-bottom: 20px;
           }

           .invoice-box table tr.top table td.title {
               font-size: 45px;
               line-height: 45px;
               color: #333;
           }

           .invoice-box table tr.information table td {
               padding-bottom: 40px;
           }

           .invoice-box table tr.heading td {
               background: #eee;
               border-bottom: 1px solid #ddd;
               font-weight: bold;
           }

           .invoice-box table tr.details td {
               padding-bottom: 20px;
           }

           .invoice-box table tr.item td{
               border-bottom: 1px solid #eee;
           }

           .invoice-box table tr.item.last td {
               border-bottom: none;
           }

           .invoice-box table tr.total td:nth-child(5) {
               border-top: 2px solid #eee;
               font-weight: bold;
           }

           @media only screen and (max-width: 600px) {
               .invoice-box table tr.top table td {
                   width: 100%;
                   display: block;
                   text-align: center;
               }

               .invoice-box table tr.information table td {
                   width: 100%;
                   display: block;
                   text-align: center;
               }
           }

           /** RTL **/
           .rtl {
               direction: rtl;

           }

           .rtl table {
               text-align: right;
           }

           .rtl table tr td:nth-child(2) {
               text-align: left;
           }

       </style>
       </head>
       <body>
       <div class='invoice-box'>
        <table cellpadding='0' cellspacing='0'>
        <tr>
            <td colspan='12'>
                <table>
                    <tr>
                        <td class='title' style=''>
                            <img src ='" <> logo <> "' style='width:100%; max-width:250px;'>
                        </td>

                        <td style='text-align:right;font-size:16px'>
                            <h4>Proforma Invoice #: " <> id <> "<br></h4>
                            Created: " <> to_string(DateTime.utc_now()) <> "<br>

                        </td>
                    </tr>
                </table>
            </td>
        </tr>

        <tr class=''>
            <td colspan='12'>
                <table>
                    <tr>
                         <td style='text-align:left;font-size:16px'>
                            Thamani Online.<br>
                            info@thamanionline.com<br>
                            Nairobi, Kenya
                        </td>

                        <td style='text-align:right;font-size:16px'>
                        Retailer: " <> retailer_name <> ".<br>
                         " <> retailer_owner <> "<br>
                         " <> retailer_email <> "
                        </td>
                    </tr>
                </table>
            </td>
        </tr>





        <tr class='heading'>
            <td>
                Item
            </td>
            <td>
                Description
            </td>
            <td>
                Qty
            </td>

            <td>
                Price
            </td>
        </tr>



        <tr class='item '>
            <td>
                " <> name <> "
            </td>

            <td>
                " <> description <> "
            </td>
            <td>
                " <> quantity <> "
            </td>
            <td>
                " <> :erlang.float_to_binary(value, decimals: 2) <> "
            </td>
        </tr>


        <tr class='total'>
            <td colspan=''>
            <td colspan=''>
            <td colspan='2'>

            <td colspan='2'>
               <strong>Total: " <> :erlang.float_to_binary(value, decimals: 2) <> "</strong>
            </td>
        </tr>
        </table>
 </div>


       </body>
       </html>"

    file_name = PdfGenerator.generate!(html, page_size: "A4", filename: scode)
    pdf_file = File.rename(file_name, "uploads/manufacturer/" <> scode <> ".pdf")

    case Repo.update(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "dispatch updated successfully.")
        |> redirect(to: dispatch_retailer_path(conn, :index))

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          dispatch: dispatch,
          changeset: changeset,
          file: file,
          pdf_file: pdf_file,
          bat: bat,
          company: company,
          count_stock: count_stock,
          count_order: count_order,
          count_order_retman: count_order_retman,
          count_return: count_return,
          count_return_retail: count_return_retail
        )
    end
  end

  def delete(conn, %{"id" => id}, current_user) do
    user = current_user

    dispatch =
      user
      |> user_dispatch_by_id(id)

    if current_user.id == dispatch.user_id do
      Repo.delete!(dispatch)

      conn
      |> put_flash(:info, "dispatch deleted successfully.")
      |> redirect(to: dispatch_retailer_path(conn, :index))
    else
      conn
      |> put_flash(:error, "You can’t delete this dispatch")
      |> redirect(to: dispatch_retailer_path(conn, :index))
    end
  end

  defp user_dispatch(user) do
    Ecto.assoc(user, :dispatches_retailer)
  end

  defp user_dispatch_by_id(user, id) do
    user
    |> user_dispatch
    |> Repo.get(id)
  end
end
