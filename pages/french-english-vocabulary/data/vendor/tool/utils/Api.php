<?php
/**
* @author Thomas Pellissier Tanon
* @copyright 2011 Thomas Pellissier Tanon
* @licence http://www.gnu.org/licenses/gpl.html GNU General Public Licence
*/

/**
* a base class for communications with Wikisource
*/
class Api {
        const USER_AGENT = 'Wikisource Export/0.1';
        public $lang = '';
        public $domainName = '';

        /**
        * @var $lang the lang of Wikisource like 'en' or 'fr'
        */
        public function __construct($lang = '', $domainName = '') {
                if($lang == '') {
                        $this->lang = Api::getHttpLang();
                } else {
                        $this->lang = $lang;
                }

                if($domainName != '') {
                        $this->domainName = $domainName;
                } elseif($this->lang == 'www' || $this->lang == '') {
                        $this->domainName = 'wikisource.org';
                        $this->lang = '';
                } elseif($this->lang == 'wl' || $this->lang == 'wikilivres') {
                        $this->domainName = 'wikilivres.ca';
                        $this->lang = '';
                } else {
                        $this->domainName = $this->lang . '.wikisource.org';
                }
        }

        /**
        * api query
        * @var $params an associative array for params send to the api
        * @return an array with whe relsult of the api query
        * @throws HttpException
        */
        public function query($params) {
                $data = 'action=query&format=php&' . http_build_query($params);
                $url = $this->domainName . '/w/api.php?' . $data;
                $response = $this->get($url);
                return unserialize($response);
        }

        /**
        * api query. Give all pages of response
        * @var $params an associative array for params send to the api
        * @return an array with whe relsult of the api query
        * @throws HttpException
        */
        public function completeQuery($params) {
                $data = array();
                do {
                        $temp = $this->query($params);
                        if(array_key_exists('query-continue', $temp)) {
                                $keys = array_keys($temp['query-continue']);
                                $keys2 = array_keys($temp['query-continue'][$keys[0]]);
                                $params[$keys2[0]] = $continue = $temp['query-continue'][$keys[0]][$keys2[0]];
                        } else {
                              $continue = '';
                        }
                        $data = array_merge_recursive($data, $temp);
                } while($continue);
                return $data;
        }

        /**
        * @var $curl_async multi curl async object doing the request
        * @var $title the title of the page
        * @var $callback the callback to call on each request termination
        * @return the content of a page
        */
        public function getPageAsync($curl_async, $title, $id, &$responses) {
                $url = $this->domainName . '/w/index.php?action=render&title=' . urlencode($title);
                return $curl_async->addRequest($url, null, array($this, 'wrapPage'), array($id, &$responses));
        }

        /*
         * Callback called when a request started by getPageAsync() finish
         */
        public function wrapPage($data, $id, &$responses) {
                if ($data['http_code'] != 200) {
                        throw new HttpException('HTTP error ' . $data['http_code'] . ' with page ' . $id . ' that return: ' . htmlentities($data['content']), $data['http_code']);
                }
                $content = getXhtmlFromContent($this->lang, $data['content']);
                $responses[$id] = $content;
        }

        public function getPagesAsync($curl_async, $titles) {
                $responses = array();
                $keys = array();
                foreach($titles as $id => $title)
                        $keys[] = $this->getPageAsync($curl_async, $title, $id, $responses);
                foreach ($keys as $key => $id)
                        $curl_async->waitForKey($id);
                return $responses;
        }

       /**
        * @var $curl_async multi curl async object doing the request
        * @var $title the title of the page
        * @var $callback the callback to call on each request termination
        * @return the content of a page
        */
        public function getImageAsync($curl_async, $url, $id, &$responses) {
                return $curl_async->addRequest($url, null, array($this, 'endImage'), array($id, &$responses));
        }

        /*
         * Callback called when a request started by getImageAsync() finish
         */
        public function endImage($data, $id, &$responses) {
                if ($data['http_code'] != 200) {
                        throw new HttpException('HTTP error ' . $data['http_code'] . ' with image ' . $id . ' that return: ' . htmlentities($data['content']), $data['http_code']);
                }
                $content = $data['content'];
                $responses[$id] = $content;
        }

        /*
         * 
         */
        function getImagesAsync($curl_async, $urls) {
                $responses = array();
                $keys = array();
                foreach($urls as $id => $url)
                        $keys[] = $this->getImageAsync($curl_async, $url, $id, $responses);
                foreach ($keys as $key => $id)
                        $curl_async->waitForKey($id);
                return $responses;
        }

        /**
        * @var $title the title of the page
        * @return the content of a page
        */
        public function getPage($title) {
                $url = $this->domainName . '/w/index.php?action=render&title=' . str_replace('%26quot%3B', '"', rawurlencode($title));
                $response = $this->get($url);
                return getXhtmlFromContent($this->lang, $response);
        }


        /**
        * @var $title array|string the title of the pages
        * @return array|string the content of the pages
        */
        public function getPages($titles) {
                $urls = array();
                foreach($titles as $id => $title) {
                        $urls[$id] = $this->domainName . '/w/index.php?action=render&title=' . str_replace('%26quot%3B', '"', rawurlencode($title));
                }
                $responses = $this->getMulti($urls);
                foreach($responses as $id => $response) {
                        $responses[$id] = getXhtmlFromContent($this->lang, $response);
                }
                return $responses;
        }

        /**
        * @var $url the url
        * @return the file content
        */
        public function get($url) {
                $ch = Api::getCurl($url);
                $response = curl_exec($ch);
                if(curl_errno($ch)) {
                        throw new HttpException(curl_error($ch), curl_errno($ch));
                } else if(curl_getinfo($ch, CURLINFO_HTTP_CODE) >= 400) {
                        throw new HttpException('HTTP error: ' . $url, curl_getinfo($ch, CURLINFO_HTTP_CODE));
                }
                curl_close($ch);
                return $response;
        }

        /**
        * multi requests
        * @var $title array|string the urls
        * @return array|string the content of a pages
        */
        public function getMulti($urls) {
                $mh = curl_multi_init();
                $curl_array = array();
                foreach($urls as $id => $url) {
                        $curl_array[$id] = Api::getCurl($url);
                        curl_multi_add_handle($mh, $curl_array[$id]);
                }
                $running = null;
                do {
                        $status = curl_multi_exec($mh, $running);
                } while ($status === CURLM_CALL_MULTI_PERFORM || $running > 0);

                $res = array();
                foreach($urls as $id => $url) {
                        $res[$id] = curl_multi_getcontent($curl_array[$id]);
                        curl_multi_remove_handle($mh, $curl_array[$id]);
                }
                curl_multi_close($mh);
                return $res;
        }

        /**
        * @var $url the url
        * @return curl
        */
        static function getCurl($url) {
                $ch = curl_init($url);
                curl_setopt($ch, CURLOPT_USERAGENT, Api::USER_AGENT);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
                curl_setopt($ch, CURLOPT_MAXREDIRS, 4);
                return $ch;
        }

        /**
        * @return the lang of the Wikisource used
        */
        public static function getHttpLang() {
                $lang = '';
                if(isset($_GET['lang'])) {
                        $lang = $_GET['lang'];
                } else if(isset($_SERVER['HTTP_ACCEPT_LANGUAGE'])) {
                        $langs = explode(',',$_SERVER['HTTP_ACCEPT_LANGUAGE']);
                        if(isset($langs[0])) {
                                $langs = explode('-', $langs[0]);
                                $lang = $langs[0];
                        }
                }
                return strtolower($lang);
        }

        /**
        * @return the url encoded like mediawiki does.
        */
        public static function mediawikiUrlEncode($url) {
                $search = array('%21', '%24', '%28', '%29', '%2A', '%2C', '%2D', '%2E', '%2F', '%3A', '%3B', '%40');
                $replace = array('!', '$', '(', ')', '*', ',', '-', '.', '/', ':', ';', '@');
                return str_replace($search, $replace, urlencode(str_replace(' ', '_', $url)));
        }
}
